% Start (or reuse) a parallel pool with num_workers workers. Returns 0,
% i.e. run serially, if num_workers is 0 or parallel pools aren't
% available (no Parallel Computing Toolbox). Used by phase_avg_STB (phase
% bins) and time_avg_STB (frame chunks).
function num_workers = start_pool(num_workers)
if num_workers <= 0
    num_workers = 0;
    return
end
if ~license('test', 'Distrib_Computing_Toolbox') || isempty(ver('parallel'))
    warning("STB:noParallel",...
        "Parallel Computing Toolbox not available, processing serially")
    num_workers = 0;
    return
end

pool = gcp('nocreate');
if ~isempty(pool) && pool.NumWorkers ~= num_workers
    delete(pool);
    pool = [];
end
if isempty(pool)
    parpool(num_workers);
end
end
