# Run `asciinema rec example_slow.json`, make the recording, then run the following to speed it up and make an svg.
# Uses https://github.com/marionebl/svg-term-cli and https://asciinema.org/

using Printf

function speed_up_asciicinema(io, input_file_name; speedup=10.0)
    f = str -> begin
        num = parse(Float64,str)
        "[$(@sprintf("%2.6f", num / speedup)), \"o\","
    end
    for line in readlines(input_file_name)
        out =  findfirst(r"\[.*, \"o\",", line)
        if !isnothing(out) && out.start == 1
            m = match(r"\[(.*), \"o\",", line)
            new_line = replace(line, r"\[(.*), \"o\"," => f(m.captures[]), count=1 )
        else
            new_line = line
        end
        println(io, new_line)
    end
end

open("example.json", "w") do f
    speed_up_asciicinema(f, "example_slow.json")
end

run(`cat example.json | svg-term --out=example.svg`)