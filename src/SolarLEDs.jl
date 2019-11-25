module SolarLEDs

export main, spaceship_dj, sun_wind_switch

using LibSerialPort, Blink, Interact, COBS, ProgressMeter, Flatten, StaticArrays

#remove this
function get_port_list(;nports_guess::Integer=64)
    ports = sp_list_ports()
    port_list = String[]
    for port in unsafe_wrap(Array, ports, nports_guess, own=false)
        port == C_NULL && return port_list
        push!(port_list, sp_get_port_name(port))
    end
    sp_free_port_list(ports)
    return port_list
end


const N_UPLOAD_ATTEMPTS = 10
const BUTTON_LABELS = vcat(string.(0:9), "#", "*", "→", "↑", "←", "↓", "OK")
const N_BUTTONS = length(BUTTON_LABELS)
const BAUD = 115200

function tobytes(x::Integer)
    low = UInt8(x & 0xFF)
    high = UInt8((x >> 8) & 0xFF)
    return low, high
end
tobytes(x::Number) = tobytes(Int(x))
struct Sun
    int::UInt8
    low::UInt8
    high::UInt8
    siz::UInt8
end
function Sun(card, pos, rad, int, n_leds_per_strip) 
    pos -= 1 + rad
    if card == :NS
        pos += n_leds_per_strip
    end
    low, high = tobytes(pos)
    return Sun(int, low, high, 2rad + 1)
end
function guiaxes(setup)
    card = radiobuttons(setup.cardinals)
    pos = slider(setup.elevations, value = 1)
    rad = slider(setup.radii, value = 0)
    int = slider(setup.intensities, value = 0)
    on(pos) do p
        a = p - 1
        if rad[] > a
            rad[] = a
        end
        a = setup.n_leds_per_strip - p[]
        if rad[] > a
            rad[] = a
        end
    end
    on(rad) do r
        a = r + 1
        if pos[]  < a
            pos[] = a
        end
        a = setup.n_leds_per_strip - r
        if pos[] > a
            pos[] = a
        end
    end
    output = map(Sun, card, pos, rad, int, setup.n_leds_per_strip)
    wdg = Widget{:sun}(["card" => card, "pos" => pos, "rad" => rad, "int" => int], output = output)
    @layout! wdg vbox( pad(1em, hbox("Cardinal axes", :card)), pad(1em, hbox("Position", :pos)), pad(1em, hbox("Radius", :rad)), pad(1em, hbox("Intensity", :int)))
end

function Sun(pos, rad, int)
    pos -= 1 + rad
    low, high = tobytes(pos)
    return Sun(int, low, high, 2rad + 1)
end
function guiazimuth(n_leds_per_strip)
    pos = slider(1:n_leds_per_strip, value = 1)
    rad = slider(0:21, value = 0)
    int = slider(0:255, value = 0)
    on(pos) do p
        a = p - 1
        if rad[] > a
            rad[] = a
        end
        a = n_leds_per_strip - p
        if rad[] > a
            rad[] = a
        end
    end
    on(rad) do r
        a = r + 1
        if pos[]  < a
            pos[] = a
        end
        a = n_leds_per_strip - r
        if pos[] > a
            pos[] = a
        end
    end

    output = map(Sun, pos, rad, int)
    wdg = Widget{:sunazimuth}(["pos" => pos, "rad" => rad, "int" => int], output = output)
    @layout! wdg vbox(pad(1em, hbox("Position", :pos)), pad(1em, hbox("Radius", :rad)), pad(1em, hbox("Intensity", :int)))
end

#=function guisuns(sp, azimuth, n_leds_per_strip)
    suns = azimuth ? [guiazimuth(n_leds_per_strip) for i in 1:4] : [guiaxes(n_leds_per_strip) for i in 1:4]
    output = map(suns...) do ss...
        SVector(flatten(ss))
    end
    on(output) do pl
        encode(sp, [0x00; pl])
    end
    d = Dict("sun$i" => s for (i,s) in enumerate(suns))
    wdg = Widget{:suns}(d, output = output)
    @layout! wdg hbox(:sun1, :sun2, :sun3, :sun4)
end=#

#=function bytes2gui(int, low, high, siz)
pos = Int(low | high << 8) + 1
rad = Int((siz - 1)/2)
pos += rad
pos, card = pos > n_leds_per_strip ? (pos - n_leds_per_strip, :NS) : (pos, :EW)
(card, pos, rad, int)
end
function setgui(b, msg)
for i in 1:4
fr = msg[1 + 4*(i - 1) : 4i]
card, pos, rad, int = bytes2gui(fr...)
l = Symbol("sun$i")
sun = b[l]
sun[:card][] = card
sun[:pos][] = pos
sun[:rad][] = rad
sun[:int][] = int
sun[] = sun[]
end
# b[] = b[]
end=#
function uploaded(sp, msg)
    encode(sp, msg)
    @showprogress 0 "Uploading..." for i in 1:100
        if bytesavailable(sp) > 0
            return true
        else
            sleep(0.1)
        end
    end
    return false
end
function attemptupload(sp, msg)
    for attempt = 1:N_UPLOAD_ATTEMPTS
        if uploaded(sp, msg)
            msg2 = decode(sp)
            if msg2 == msg
                return nothing
            end
        end
        println("attempt #$attempt to upload data failed...")
    end
    error("failed to upload data after $N_UPLOAD_ATTEMPTS attempts")
end

#=function _main(azimuth, n_leds_per_strip)


    ports = get_port_list()
    if isempty(ports)
        error("no ports were detected...")
    end
    dd = dropdown(ports, value = last(ports))

    serialport = map(dd) do sp
        open(sp, BAUD)
    end
    bottoms = Dict(l => map(x -> guisuns(x, azimuth, n_leds_per_strip), serialport) for l in BUTTON_LABELS)
    top = tabs(BUTTON_LABELS)
    bottom = map(top) do l
        bottoms[l][]
    end;
    =##=download = button("Download")
    on(download) do _
    l = top[]
    i = UInt8(findfirst(isequal(l), BUTTON_LABELS) - 1)
    uploaded([0x02, i])
    msg = decode(serialport)
    setgui(bottoms[l], msg)
    # bottom[] = bottom[]
    end=##=
    upload = button("Upload")
    on(upload) do _
        l = top[]
        i = UInt8(findfirst(isequal(l), BUTTON_LABELS) - 1)
        msg = vcat(0x01, i, bottom[][])
        attemptupload(serialport[], msg)
    end
    uploadall = button("Upload all")
    on(uploadall) do _
        for (i,l) in enumerate(BUTTON_LABELS)
            b = bottoms[l]
            msg = vcat(0x01, i - 1, b[])
            attemptupload(serialport[], msg)
        end
    end
    reset = button("Reset")
    on(reset) do _
        flush(serialport[])
        uploaded(serialport[], [UInt8(3)])
        @assert Bool(decode(serialport[])[])
    end
    w = Window()
    body!(w, vbox(hbox("Port", dd), dom"div"(hbox(pad(1em, uploadall), pad(1em, upload), pad(1em, reset)), top, bottom)))

    return nothing
end=#

# sun_wind_switch() = _main(false, 150)
# spaceship_dj() = _main(true, 73)

struct Setup
    nsuns::Int
    n_leds_per_strip::Int
    cardinals::Vector{Symbol}
    elevations::Vector{Int}
    radii::Vector{Int}
    intensities::Vector{Int}
end

function main(; n_leds_per_strip::Int = 150, cardinals = [:EW, :NS], elevations = 1:150, radii = 0:25, intensities = 0:255) 
    nsuns = 1
    @assert 0 < nsuns "number of suns must be larger than zero"
    @assert 0 < n_leds_per_strip "number of LEDs per strip must be larger than zero"
    main(Setup(nsuns, n_leds_per_strip, cardinals, elevations, radii, intensities))
end

sun_wind_switch() = main(n_leds_per_strip = 141, elevations = [5, 20, 45, 60, 75, 80, 82, 84, 86, 88, 90], radii = [0], intensities = [255])
spaceship_dj() = main(n_leds_per_strip = 73, elevations = [1,2,3,4], radii = [0,1,2], intensities = 1:255, cardinals = [:NA])

function goodport(port) 
    try
        sp = open(port, BAUD)
        close(sp)
    catch 
        return false
    end
    return true
end

function main(setup)


    ports = get_port_list()
    filter!(goodport, ports)
    if isempty(ports)
        error("no ports were detected...")
    end
    dd = dropdown(ports, value = last(ports))

    serialport = map(dd) do sp
        open(sp, BAUD)
    end
    bottoms = Dict(l => map(x -> guisuns(x, setup), serialport) for l in BUTTON_LABELS)
    top = tabs(BUTTON_LABELS)
    bottom = map(top) do l
        bottoms[l][]
    end
    #=download = button("Download")
    on(download) do _
    l = top[]
    i = UInt8(findfirst(isequal(l), BUTTON_LABELS) - 1)
    uploaded([0x02, i])
    msg = decode(serialport)
    setgui(bottoms[l], msg)
    # bottom[] = bottom[]
    end=#
    upload = button("Upload")
    on(upload) do _
        l = top[]
        i = UInt8(findfirst(isequal(l), BUTTON_LABELS) - 1)
        msg = vcat(0x01, i, bottom[][])
        attemptupload(serialport[], msg)
    end
    uploadall = button("Upload all")
    on(uploadall) do _
        for (i,l) in enumerate(BUTTON_LABELS)
            b = bottoms[l]
            msg = vcat(0x01, i - 1, b[])
            attemptupload(serialport[], msg)
        end
    end
    reset = button("Reset")
    on(reset) do _
        flush(serialport[])
        uploaded(serialport[], [UInt8(3)])
        @assert Bool(decode(serialport[])[])
    end
    w = Window()
    body!(w, vbox(hbox("Port", dd), dom"div"(hbox(pad(1em, uploadall), pad(1em, upload), pad(1em, reset)), top, bottom)))

    return nothing
end

function guisuns(sp, setup)
    suns = [guiaxes(setup) for i in 1:setup.nsuns]
    output = map(suns...) do ss...
        SVector(flatten(ss))
    end
    on(output) do pl
        encode(sp, [0x00; pl])
    end
    d = Dict("sun$i" => s for (i,s) in enumerate(suns))
    wgt = Widget{:suns}(d, output = output)
    @layout! wgt vbox(:sun1)
end

### TODO
# implement downloading
# maybe prepare hosting this to a server for mobile interface


end # module
