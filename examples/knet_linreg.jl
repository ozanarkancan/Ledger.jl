if Pkg.installed("Ledger") == nothing
    Pkg.clone("https://github.com/ozanarkancan/Ledger.jl.git")
end

for p in ("Knet","ArgParse")
    Pkg.installed(p) == nothing && Pkg.add(p)
end

using Knet, Ledger

include(Pkg.dir("Knet","data","housing.jl"))

predict(w,x)=(w[1]*x.+w[2])

loss(w,x,y)=(sum(abs2,y-predict(w,x)) / size(x,2))

lossgradient = grad(loss)

function train(w, x, y; lr=.1, epochs=20)
    for epoch=1:epochs
        g = lossgradient(w, x, y)
        update!(w, g; lr=lr)
    end
    return w
end

function experimentf(;seed=-1, epochs=20, lr=0.1, test=0.0, winit=0.1)
    srand(seed)
    w = map(Array{Float32}, [winit*randn(1,13), winit*randn(1,1) ])
    (xtrn,ytrn,xtst,ytst) = map(Array{Float32}, Main.housing(test))
    experiment_log = []

    push!(experiment_log, Dict("epoch" => 0, "train-mse" => loss(w, xtrn, ytrn), "test-mse" => loss(w, xtst, ytst)))
    println(experiment_log[end])

    for i=1:epochs
        train(w, xtrn, ytrn; lr=lr, epochs=1)
        push!(experiment_log, Dict("epoch" => i, "train-mse" => loss(w, xtrn, ytrn), "test-mse" => loss(w, xtst, ytst)))
        println(experiment_log[end])
        sleep(0.5)
    end
    return experiment_log, Dict("test-mse" => loss(w, xtst, ytst))
end

function main()
    engine = LedgerEngine("mongodb://localhost:27017")
    configf = Dict(:seed=>123, :epochs=>100, :lr=>0.1, :test=>0.0, :winit=>0.1)
    Ledger.run(engine, "housing", "linear-regression", experimentf, configf, ["epoch", "train-mse", "test-mse"])
end

PROGRAM_FILE=="knet_linreg.jl" && main()
