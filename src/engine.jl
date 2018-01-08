using Mongo, LibBSON

mutable struct LedgerEngine
    client::Mongo.MongoClient
end

function LedgerEngine(hostname::String)
    client = MongoClient(hostname)
    return LedgerEngine(client)
end

function run(engine::LedgerEngine, projname::String, modelname::String, f, configf, headers)
    ccall(:jl_exit_on_sigint, Void, (Cint,), 0)
    start_time = now()
    try
        exp_log, res = f(;configf...)
        stop_time = now()

        convertedconfig = Dict()
        for k in keys(configf); convertedconfig[String(k)] = configf[k]; end;
        rec = Dict()
        rec["project_name"] = projname
        rec["model_name"] = modelname
        rec["config"] = convertedconfig
        rec["experiment_headers"] = headers
        rec["experiment_log"] = exp_log
        rec["result"] = res
        rec["start_time"] = start_time
        rec["stop_time"] = stop_time
        rec["status"] = "completed"
        runs = MongoCollection(engine.client, "ledger", "runs")
        insert(runs, rec)
    catch ex
        if isa(ex, InterruptException)
            stop_time = now()
            convertedconfig = Dict()
            for k in keys(configf); convertedconfig[String(k)] = configf[k]; end;
            rec = Dict()
            rec["project_name"] = projname
            rec["model_name"] = modelname
            rec["config"] = convertedconfig
            rec["experiment_headers"] = headers
            rec["start_time"] = start_time
            rec["stop_time"] = stop_time
            rec["status"] = "interrupted"
            runs = MongoCollection(engine.client, "ledger", "runs")
            insert(runs, rec)
        end
    end
end
