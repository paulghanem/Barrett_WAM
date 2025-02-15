function params = exTestGraspSetup(input_grasp_plan_name,experiment,callbackData)
%EXTESTGRASPSETUP Summary of this function goes here
%   Detailed explanation goes here

    global tformInfo;
    global arm_ready;
    global arm_home_norest;
    
    %grasp_plan_directory = 'C:\Users\robotics\Documents\MATLAB\wam_controller\WAM7DOF\GraspPlans\';
    %grasp_plan_directory = 'C:\Users\robotics\Documents\MATLAB\wam_controller\matlab_graspit_interface\matlab\graspplan\'
    %grasp_plan_directory = 'C:\Users\robotics\Documents\MATLAB\wam_controller\matlab_graspit_interface\matlab\newgraspplan\';
    %grasp_plan_directory = '/home/emma/HarrisProject/HarrisRPI/trunk/matlab_graspit_interface/matlab/graspplan/';
    grasp_plan_directory = '';
    grasp_plan_filename = 'temp_plans.txt';
    
    %grasp_plan_filename = 'rabbit.txt';
    %grasp_plan_filename = 'planresult_Perception_Scenario_1.txt'; % Brick
    %grasp_plan_filename = 'planresult_Perception_Scenario_2.txt'; % Hat
    %grasp_plan_filename = 'planresult_Perception_Scenario_3.txt'; % Tumbler
    %grasp_plan_filename = 'planresult_Perception_Scenario_4.txt'; % Cinder block
    %grasp_plan_filename = 'planresult_Perception_Scenario_5.txt'; % Brick
    %grasp_plan_filename = 'planresult_Perception_Scenario_6.txt'; % Hat
    %grasp_plan_filename = 'planresult_Perception_Scenario_6_new.txt';
    %grasp_plan_filename = 'planresult_Perception_Scenario_7_new.txt';

    %grasp_plan_filename = 'cube_grasp_plan.txt';
    
    %grasp_plan_filename = 'right_finger_touch_graspplans.txt';
    
    %%%  RUN THESE FOR SET 3
    %grasp_plan_filename = 'both_fingertip_touch_graspplans.txt';
    %grasp_plan_filename = 'left_fingertip_touch_down_graspplans.txt';
    %grasp_plan_filename = 'left_finger_back_touch_down_graspplans.txt';
    %grasp_plan_filename = 'left_finger_touch_down_graspplans.txt';
    %grasp_plan_filename = 'palm_brim_touch_graspplans.txt';
    %grasp_plan_filename = 'right_fingertip_touch_down_graspplans.txt';
    %grasp_plan_filename = 'right_finger_back_touch_down_graspplans.txt';
    %grasp_plan_filename = 'right_finger_touch_down_graspplans.txt';
    %%%

    %grasp_plan_filename = 'fingertip_touch_graspplans.txt'; % Touches hat on edge of brim
    %grasp_plan_filename = 'left_fingertip_touch_brim_graspplans.txt';
        
    %grasp_plan_filename = 'left_finger_back_touch_up_graspplans.txt';
    %grasp_plan_filename = 'left_finger_touch_up_graspplans.txt';
    %grasp_plan_filename = 'palm_touch_graspplans.txt';
    %grasp_plan_filename = 'right_fingertip_touch_brim_graspplans.txt';
    %grasp_plan_filename = 'right_fingertip_touch_side_graspplans.txt';
    %grasp_plan_filename = 'right_finger_back_touch_up_graspplans.txt';
    %grasp_plan_filename = 'right_finger_touch_up_graspplans.txt';
    
    % If a path was provided use that path, otherwise build path from uncommented lines above
    if nargin == 0
        full_grasp_plan_name = strcat(grasp_plan_directory,grasp_plan_filename);
    else
        full_grasp_plan_name = input_grasp_plan_name;
    end
    
    robotid = orEnvGetBody('BarrettWAM');
    real_execution_mode = false;
    
    ttProjectFile = 'C:\Users\robotics\Documents\MATLAB\wam_controller\CameraCalibrations\Project20120520.ttp';
    
    waypointIndex = 1;
    
    
    % If a path was provided use that path, otherwise build path from uncommented lines above
    if nargin == 0
        [ objectid planStruct object_T plotIDs ] = exVisualizeGraspPlan(full_grasp_plan_name,tformInfo,ttProjectFile,waypointIndex);
    else
        [ objectid planStruct object_T plotIDs ] = exVisualizeGraspPlan(full_grasp_plan_name,tformInfo,ttProjectFile,waypointIndex,experiment,callbackData);
    end
    
    
    
    
    % if something screws up, shutdown the system gracefully
    c = onCleanup(@()exCleanup(plotIDs,objectid,robotid));
    
    idAccepted = 0;
    
    if ~isempty(plotIDs)
    
        while idAccepted == 0

            id = input('Enter pregrasp id to execute\n');
            qi = [arm_ready'; 0; 0];

            if ~real_execution_mode
                for i = 1:planStruct.plans(id).nPts
                    %TobjTip = planStruct.plans(id).waypoints(i).Htransform;
                    %pregraspT = object_T * TobjTip
                    
                    pregraspT = planStruct.plans(id).waypoints(i).Htransform;
                    
                    [~, qip1] = wam7ik_w_joint_limits(pregraspT, qi(1:7));
                    qip1
                    qip1 = [qip1; 0; planStruct.plans(id).waypoints(i).gripWidth/2];
                    TRAJ = jointSpaceTraj(qi,qip1);
                    exDisplayTrajectory(1,TRAJ,1);
                    qi = qip1;
                end
            else
                % create problem instances
                probs.cbirrt = orEnvCreateProblem('CBiRRT','BarrettWAM');
                % set display options
                orEnvSetOptions('debug 3')
                orEnvSetOptions('collision ode')

                qi = [arm_ready'; 0; 0.100];
                orRobotSetDOFValues(robotid, qi, 0:8);
                %get the descriptions of the robot's manipulators
                manips = orRobotGetManipulators(robotid);
                orRobotSetActiveDOFs(robotid, manips{1}.armjoints);
                for i = 1:planStruct.plans(id).nPts
                    TobjTip = planStruct.plans(id).waypoints(i).Htransform;
                    %pregraspT = object_T * TobjTip; % If plans are in object frame
                    pregraspT = TobjTip; % If plans are in world frame
                    switch i
                        case 1
                            fprintf('Case %d\n',i);
                            try
                            [~, TRAJ, ~] = orTrajPlanningHelper(pregraspT, probs.cbirrt);
                            catch e
                                disp('Trajectory planner cannot find a solution.')
                                break;
                            end
                            gripper_TRAJ = jointSpaceTraj(qi(end), planStruct.plans(id).waypoints(i).gripWidth, size(TRAJ, 2));
                            TRAJ = [TRAJ; zeros(1, size(TRAJ, 2)); gripper_TRAJ];
                            qip1 = TRAJ(:, end);
                        case 2
                            fprintf('Case %d\n',i);
                            [ valid, TRAJ ] = wam7_straightline_traj_gen(qip1(1:7), pregraspT,100,.1);
                            TRAJ
                            if valid
                                gripper_TRAJ = jointSpaceTraj(qi(end), planStruct.plans(id).waypoints(i).gripWidth, size(TRAJ, 2));
                                TRAJ = [TRAJ; zeros(1, size(TRAJ, 2)); gripper_TRAJ];
                                qip1 = TRAJ(:, end);
                            else
                                disp('Trajectory planner cannot find a solution.')
                                break;
                            end 
                        case 3
                            fprintf('Case %d\n',i);
                            [~, qip1] = wam7ik_w_joint_limits(pregraspT, qi(1:7));
                            qip1 = [qip1; 0; planStruct.plans(id).waypoints(i).gripWidth];
                            TRAJ = jointSpaceTraj(qi, qip1);
                        case 4
                            fprintf('Case %d\n',i);
                            [~, qip1] = wam7ik_w_joint_limits(pregraspT, qi(1:7));
                            qip1 = [qip1; 0; planStruct.plans(id).waypoints(i).gripWidth];
                            TRAJ = jointSpaceTraj(qi, qip1);
                        case 5
                            fprintf('Case %d\n',i);
                            [ valid, TRAJ ] = wam7_straightline_traj_gen(qi(1:7), pregraspT,100,.1);
                            if valid
                                gripper_TRAJ = jointSpaceTraj(qi(end), planStruct.plans(id).waypoints(i).gripWidth, size(TRAJ, 2));
                                TRAJ = [TRAJ; zeros(1, size(TRAJ, 2)); gripper_TRAJ];
                                qip1 = TRAJ(:, end);
                            else
                                disp('Trajectory planner cannot find a solution.')
                                break;
                            end
                        otherwise
                            fprintf('Case %d\n',i);
                            [~, qip1] = wam7ik_w_joint_limits(pregraspT, qi(1:7));
                            qip1 = [qip1; 0; planStruct.plans(id).waypoints(i).gripWidth];
                            TRAJ = jointSpaceTraj(qi, qip1);
                    end
                    exDisplayTrajectory(1,TRAJ,3);
                    qi = qip1;
                end
            end
            response = input('\nDo you want to execute this plan? [Y|N|Q] ','s');
            if strcmpi(response,'y')
                idAccepted = 1;
                params.planName = full_grasp_plan_name;
                params.planToRun = id;
            elseif strcmp(response,'n')
                idAccepted = 0;
            else
                idAccepted = -1;
                params.planName = full_grasp_plan_name;
                params.planToRun = -1;
            end
            orRobotSetDOFValues(robotid,[arm_home_norest(:)' 0 0], 0:8);
        end
       
    else
        params.planName = '';
        params.planToRun = 0;
    end
    
    % Set to just the plan number is we are doing in an experiment
    if nargin > 0
       params = params.planToRun; 
    end

end


function exCleanup(plotIDs,objectid,robotid)
    global arm_home_norest

    try
        delete 'C:/Program Files (x86)/OpenRAVE/bin/cmovetraj.txt';
    catch e
    end

    try
        orEnvClose(plotIDs);
    catch e
    end
    
    try
        orBodyDestroy(objectid);
    catch e
    end
    
    try
        orRobotSetDOFValues(robotid,[arm_home_norest(:)' 0 0], 0:8);
    catch e
    end
end

