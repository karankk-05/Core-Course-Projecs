

function naphthaleneDiffusionGUI()
    % --- Physical Parameters ---
    D = 1e-7;            % Diffusion coefficient of naphthalene in toluene (m²/s)
    rho_naphthalene = 1050;  % Density of naphthalene (kg/m³)
    solubility_toluene = 100; % Solubility (saturation) concentration of naphthalene in toluene (kg/m³)
    C_sat = solubility_toluene;  % Corrected: Saturation equals solubility
    
    % --- Simulation Parameters ---
    initial_radius = 0.005;  % Initial radius of the naphthalene ball (5 mm)
    domain_size = 0.02;      % Size of computational domain (m)
    nr = 200;                % Number of grid points in radial direction
    n_facets = 50;           % Number of facets for rendering the sphere
    
    dt_solve = 0.05;            % Time step for solver (s)
    max_time = 1*1800;      % Maximum simulation time (24 hours in seconds)
    
    % --- Animation Parameters ---
    animation_duration = 10; % 10 seconds animation for smooth playback
    animation_steps = 200;   % Increase steps for smoother animation
    animation_dt = max_time / animation_steps;
    
    % Create radial grid
    r = linspace(0, domain_size, nr);
    dr = r(2) - r(1);
    
    % Initialize concentration field
    C = zeros(size(r));
    idx_interface = find(r >= initial_radius, 1) - 1;
    C(idx_interface+1:end) = 0;  % Initial concentration in toluene
    
    % Current radius tracking
    current_radius = initial_radius;
    
    % --- Create the GUI Figure ---
    fig = uifigure('Name', 'Naphthalene Diffusion Simulation', 'Position', [100 100 900 750]);

    % --- Create 3D Axes ---
    ax_3d = uiaxes(fig, 'Position', [50 400 400 300]);
    axis(ax_3d, 'equal');
    grid(ax_3d, 'on');
    box(ax_3d, 'on');
    hold(ax_3d, 'on');
    xlabel(ax_3d, 'X (m)');
    ylabel(ax_3d, 'Y (m)');
    zlabel(ax_3d, 'Z (m)');
    title(ax_3d, 'Naphthalene Sphere Dissolving in Toluene');
    view(ax_3d, 3);
    camlight(ax_3d, 'headlight');
    material(ax_3d, 'shiny');
    ax_3d.XLim = [-domain_size, domain_size];
    ax_3d.YLim = [-domain_size, domain_size];
    ax_3d.ZLim = [-domain_size, domain_size];

    % --- Create Concentration Profile Axes ---
    ax_conc = uiaxes(fig, 'Position', [500 400 350 300]);
    hold(ax_conc, 'on');
    xlabel(ax_conc, 'Radial Distance (m)');
    ylabel(ax_conc, 'Concentration (kg/m³)');
    title(ax_conc, 'Naphthalene Concentration Profile');
    
    % Create a plot of initial concentration
    h_conc = plot(ax_conc, r, C, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
    ax_conc.YLim = [0, C_sat*1.1];
    ax_conc.XLim = [0, domain_size];
    h_interface = xline(ax_conc, current_radius, 'r--', 'Interface');
    
    % --- Create Time Controls ---
    time_panel = uipanel(fig, 'Title', 'Simulation Time', ...
        'Position', [50 300 800 80]);
    
    time_slider = uislider(time_panel, ...
        'Position', [100 40 600 3], ...
        'Limits', [0, max_time], ...
        'Value', 0, ...
        'MajorTicks', linspace(0, max_time, 7), ...
        'MajorTickLabels', arrayfun(@(t) sprintf('%.1f h', t/3600), linspace(0, max_time, 7), 'UniformOutput', false), ...
        'MinorTicks', []);

    time_label = uilabel(time_panel, ...
        'Position', [350 15 200 22], ...
        'Text', sprintf('Time: %.2f hours', time_slider.Value/3600), ...
        'HorizontalAlignment', 'center');

    % --- Create Physical Information Panel ---
    param_panel = uipanel(fig, 'Title', 'Diffusion Parameters and Model Information', ...
        'Position', [50 180 800 100]);
    
    % Left column - Physical parameters
    uilabel(param_panel, 'Position', [20 60 350 22], ...
        'Text', sprintf('Diffusion Coefficient: %.2e m²/s', D));
    
    uilabel(param_panel, 'Position', [20 30 350 22], ...
        'Text', sprintf('Naphthalene Density: %.1f kg/m³', rho_naphthalene));
    
    uilabel(param_panel, 'Position', [20 0 350 22], ...
        'Text', sprintf('Saturation Concentration: %.1f kg/m³', C_sat));
    
    % Middle column - Model information
    uilabel(param_panel, 'Position', [380 60 350 22], ...
        'Text', 'Model: Fick''s Second Law (Spherical Coordinates)');
    
    uilabel(param_panel, 'Position', [380 30 350 22], ...
        'Text', 'Equation: ∂C/∂t = D·[∂²C/∂r² + (2/r)·(∂C/∂r)]');
    
    % Solubility status indicator
    solubility_status = uilabel(param_panel, 'Position', [380 0 350 22], ...
        'Text', 'Dissolution Status: Active', ...
        'FontColor', [0 0.7 0]);
    
    % Right column - Current state
    radius_label = uilabel(param_panel, 'Position', [600 60 200 22], ...
        'Text', sprintf('Current Radius: %.2f mm', current_radius*1000));
    
    flux_label = uilabel(param_panel, 'Position', [600 30 200 22], ...
        'Text', 'Flux: 0.00 kg/m²·s');
    
    rate_label = uilabel(param_panel, 'Position', [600 0 200 22], ...
        'Text', 'Dissolution Rate: 0.00 mm/h');
    
    % --- Create Visualization Toggle ---
    viz_panel = uipanel(fig, 'Title', 'Visualization Options', ...
        'Position', [50 100 800 60]);
    
    % Create radio button group for visualization mode
    bg = uibuttongroup(viz_panel, 'Position', [0.1 0.1 0.8 0.8], ...
        'SelectionChangedFcn', @updateVizMode);
    
    rb1 = uiradiobutton(bg, 'Text', 'Show Naphthalene Sphere Only', ...
        'Position', [10 10 230 22]);
    
    rb2 = uiradiobutton(bg, 'Text', 'Show Concentration Field', ...
        'Position', [250 10 230 22]);
    
    % --- Create Simulation Control Buttons ---
    start_button = uibutton(fig, 'push', ...
        'Position', [250 50 200 30], ...
        'Text', 'Start Auto Simulation', ...
        'ButtonPushedFcn', @startAnimation);
    
    reset_button = uibutton(fig, 'push', ...
        'Position', [470 50 200 30], ...
        'Text', 'Reset Simulation', ...
        'ButtonPushedFcn', @resetSimulation);
    
    % --- Create timer for animation ---
    timer_obj = timer('ExecutionMode', 'fixedRate', ...
                     'Period', animation_duration/animation_steps, ...
                     'TimerFcn', @autoUpdateSlider);
    
    % --- Initialize visualization objects ---
    % Generate sphere coordinates
    [x0, y0, z0] = sphere(n_facets);
    x = x0 * current_radius;
    y = y0 * current_radius;
    z = z0 * current_radius;
    
    % Plot the initial sphere surface
    h_surf = surf(ax_3d, x, y, z, 'FaceColor', 'yellow', 'EdgeColor', 'none');
    
    % Add a slice visualization for concentration (initially invisible)
    [X, Y, Z] = meshgrid(linspace(-domain_size, domain_size, 50));
    R = sqrt(X.^2 + Y.^2 + Z.^2);
    C_vis = zeros(size(R));
    h_slice = slice(ax_3d, X, Y, Z, C_vis, 0, 0, 0);
    set(h_slice, 'Visible', 'off')
    
    % Initialize visualization mode
    viz_mode = 'sphere';
    rb1.Value = true;
    
    % --- Precompute Time Evolution ---
    % Arrays to store results
    n_steps = floor(max_time / dt_solve);
    radius_history = zeros(n_steps+1, 1);
    C_history = zeros(nr, n_steps+1);
    time_history = (0:n_steps) * dt_solve;
    flux_history = zeros(n_steps+1, 1);
    rate_history = zeros(n_steps+1, 1);
    dissolution_active = ones(n_steps+1, 1); % Track if dissolution is active (1) or stopped (0)
    
    % Store initial conditions
    radius_history(1) = current_radius;
    C_history(:,1) = C;
    
    % Create progress dialog
    waitdlg = uiprogressdlg(fig, 'Title', 'Computing Diffusion Evolution', ...
                               'Message', 'Please wait...');
    
    % Setup for diffusion calculation
    current_time = 0;
    C_current = C;
    
    for step = 1:n_steps
        % Update progress dialog
        waitdlg.Value = step / n_steps;
        if mod(step, 100) == 0
            waitdlg.Message = sprintf('Computing step %d of %d...', step, n_steps);
        end
        
        % Find interface location
        idx_interface = find(r >= current_radius, 1) - 1;
        if idx_interface < 1 || idx_interface >= nr - 1
            break;  % Stop if sphere has dissolved completely or boundary issues
        end
        
        % Set boundary condition at interface (saturation concentration)
        C_current(idx_interface+1) = C_sat;
        
        % Solve Fick's Second Law in spherical coordinates
        C_new = C_current;
        for i = idx_interface+2:nr-1
            % Finite difference approximation of spherical diffusion equation
            % ∂C/∂t = D * [∂²C/∂r² + (2/r)*(∂C/∂r)]
            C_new(i) = C_current(i) + dt_solve * D * (...
                (C_current(i+1) - 2*C_current(i) + C_current(i-1))/dr^2 + ...
                (2/r(i)) * (C_current(i+1) - C_current(i-1))/(2*dr));
        end
        
        % No-flux boundary condition at outer boundary
        C_new(nr) = C_new(nr-1);
        
        % Calculate flux at interface (using forward difference)
        dCdr_interface = (C_current(idx_interface+2) - C_current(idx_interface+1)) / dr;
        flux = -D * dCdr_interface;
        
        % Check if toluene has reached its solubility limit beyond the interface
        % Look for maximum concentration in the solution (r > current_radius)
        solution_C = C_current(idx_interface+2:end);
        if max(solution_C) >= solubility_toluene
            % Find the first point where concentration exceeds solubility beyond interface
            sol_idx = find(solution_C >= solubility_toluene, 1) + idx_interface +1;
            if isempty(sol_idx)
                sol_idx = nr;
            end
            sol_distance = r(sol_idx);
            
            % If the solubility is reached beyond the interface, check if flux is zero
            if flux <= 0
                % No flux means dissolution stops
                dr_dt = 0;
                dissolution_rate = 0;
                dissolution_active(step+1) = 0;
            else
                % Continue dissolution normally
                dr_dt = -flux / rho_naphthalene;
                current_radius = current_radius + dr_dt * dt_solve;
                dissolution_active(step+1) = 1;
                dissolution_rate = -dr_dt * 3600 * 1000;  % convert m/s to mm/h
            end
        else
            % Update radius based on mass conservation normally
            dr_dt = -flux / rho_naphthalene;
            current_radius = current_radius + dr_dt * dt_solve;
            dissolution_active(step+1) = 1;
            dissolution_rate = -dr_dt * 3600 * 1000;
        end
        
        current_radius = max(0, current_radius);  % Ensure non-negative radius
        
        % Update for next step
        C_current = C_new;
        current_time = current_time + dt_solve;
        
        % Store results
        radius_history(step+1) = current_radius;
        C_history(:,step+1) = C_current;
        flux_history(step+1) = flux;
        rate_history(step+1) = dissolution_rate;
        
        % Break if sphere has completely dissolved
        if current_radius <= 0
            radius_history(step+1:end) = 0;
            for j = step+1:n_steps
                C_history(:,j) = C_current;
                flux_history(j+1) = 0;
                rate_history(j+1) = 0;
                dissolution_active(j+1) = 0;
            end
            break;
        end
    end
    
    close(waitdlg);  % Close progress dialog when done
    
    % --- Timer Callback Function ---
    function autoUpdateSlider(~, ~)
    current_val = time_slider.Value;
    if current_val >= max_time
        stop(timer_obj);
        return;
    end
    time_slider.Value = min(current_val + animation_dt, max_time);
    updatePlot();  % Force the plot to update with the new slider value
end

    
    % --- Start Animation Function ---
    function startAnimation(~, ~)
        stop(timer_obj);
        time_slider.Value = 0;
        start(timer_obj);
    end
    
    % --- Visualization Mode Callback ---
    function updateVizMode(~, event)
        viz_mode = event.NewValue.Text;
        if contains(viz_mode, 'Sphere Only')
            viz_mode = 'sphere';
        else
            viz_mode = 'concentration';
        end
        updatePlot();
    end
    
    % --- Slider Callback Function ---
    function updatePlot(~, ~)
        current_time = time_slider.Value;
        
        % Find the closest time in our precomputed history
        [~, time_idx] = min(abs(time_history - current_time));
        
        % Get values at this time
        current_radius = radius_history(time_idx);
        C_current = C_history(:, time_idx);
        current_flux = flux_history(time_idx);
        current_rate = rate_history(time_idx);
        is_active = dissolution_active(time_idx);
        
        % Update dissolution status indicator
        if is_active
            solubility_status.Text = 'Dissolution Status: Active';
            solubility_status.FontColor = [0 0.7 0];
        else
            solubility_status.Text = 'Dissolution Status: Stopped (Solubility Limit)';
            solubility_status.FontColor = [0.8 0 0];
        end
        
        % Update 3D visualization
        if strcmp(viz_mode, 'sphere')
            % Update sphere
            x = x0 * current_radius;
            y = y0 * current_radius;
            z = z0 * current_radius;
            
            h_surf.XData = x;
            h_surf.YData = y;
            h_surf.ZData = z;
            
            % Hide concentration slices
            set(h_slice, 'Visible', 'off');
            h_surf.Visible = 'on';
            
        else % 'concentration' mode
            % Create concentration visualization in 3D
            % First update the sphere
            x = x0 * current_radius;
            y = y0 * current_radius;
            z = z0 * current_radius;
            
            h_surf.XData = x;
            h_surf.YData = y;
            h_surf.ZData = z;
            
            % Then interpolate concentration field onto 3D grid for slices
            for i = 1:numel(X)
                dist = sqrt(X(i)^2 + Y(i)^2 + Z(i)^2);
                if dist < current_radius
                    C_vis(i) = 0;  % Inside naphthalene
                else
                    % Find closest radial distance in our solution
                    [~, r_idx] = min(abs(r - dist));
                    C_vis(i) = C_current(r_idx);
                end
            end
            
            % Update slice visualization
            h_slice.XData = X;
            h_slice.YData = Y;
            h_slice.ZData = Z;
            h_slice.CData = C_vis;
            
            % Make slices visible
            set(h_slice, 'Visible', 'on');
            set(h_slice, 'EdgeColor', 'none');
            
            % Add colorbar if not already present
            if ~isvalid(colorbar(ax_3d))
                colorbar(ax_3d);
            end
            
            caxis(ax_3d, [0 C_sat]);
        end
        
        % Update concentration profile plot
        h_conc.YData = C_current;
        h_interface.Value = current_radius;
        
        % Update labels
        time_label.Text = sprintf('Time: %.2f hours', current_time/3600);
        radius_label.Text = sprintf('Current Radius: %.2f mm', current_radius*1000);
        flux_label.Text = sprintf('Flux: %.2e kg/m²·s', current_flux);
        rate_label.Text = sprintf('Dissolution Rate: %.2f mm/h', current_rate);
        
        drawnow;
    end

    % --- Reset Function ---
    function resetSimulation(~, ~)
        stop(timer_obj); % Stop any running animation
        time_slider.Value = 0;
        updatePlot();
    end
    
    % Clean up timer when figure is closed
    fig.CloseRequestFcn = @closeFigure;
    function closeFigure(~, ~)
        stop(timer_obj);
        delete(timer_obj);
        delete(fig);
    end
    
    % --- Assign Slider Callback ---
    time_slider.ValueChangedFcn = @updatePlot;
    
    % --- Initial Update ---
    updatePlot();
    
end % End of main function


