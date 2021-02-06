### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 1c1f8ff4-5d6e-11eb-1252-53826a751284
begin
	using Colors
	using DataFrames
	using FileIO
	using GLM
	using Glob
	using ImageMagick
	using Images
	using Plots
	using Statistics
end

# ╔═╡ 33d0c8d2-5d70-11eb-3fd4-c1c40ec2d492
md"""
# Linear Input Data

Take a bunch of images with your camera with:

- same manual ISO
- same manual aperture
- same "picture" (motive + light + ...), ideally something white like a sheet of paper
- changing manual exposure time / shutter speed

Place the RAW images in `01_linear/`.
"""

# ╔═╡ 3b7b497c-5d70-11eb-187e-f5b8712112ba
md"""
## Setup
"""

# ╔═╡ 426ddea2-5d70-11eb-0a2b-d72b1cf13e4b
md"""
## Input
"""

# ╔═╡ 7e2e559a-5d6e-11eb-063e-83b2eabe9dcb
files = glob("01_linear/*_converted.tif")

# ╔═╡ 4ae6869c-5d70-11eb-2368-2383e580b01e
md"""
## Exposure Time
"""

# ╔═╡ 9b7b3a00-5d6e-11eb-3181-c3bdf70b5c16
function get_exposure_time(fname::String)::Float64
	tag = "exif:ExposureTime"
	s = magickinfo(fname, [tag])[tag]
	parse(Float64, s)
end

# ╔═╡ c9783106-5d6e-11eb-2433-f51692f7dd8f
exposure_times = map(get_exposure_time, files)

# ╔═╡ 58885640-5d70-11eb-2932-255058995960
md"""
## Image Data
"""

# ╔═╡ fb80bc84-5d70-11eb-1d1f-158ac70f781c
const PixelType = RGB{Float64}

# ╔═╡ 0add8372-5d71-11eb-2332-7903a219a078
const ImageType = Array{PixelType, 2}

# ╔═╡ c8fb8adc-5d70-11eb-34e2-a152a7468ba6
function load_image(fname::String)::ImageType
	img = load(fname)
	PixelType.(img)
end

# ╔═╡ 3bcdefee-5d73-11eb-2853-d95f43a59b07
function channel_mean(img::ImageType)::Array{Float64}
	dropdims(mean(channelview(img), dims=(2, 3)); dims=(2, 3))
end

# ╔═╡ 6ee64584-5d73-11eb-09b4-61d7a70f9e70
means = hcat(map(f -> channel_mean(load_image(f)), files)...)

# ╔═╡ 24147688-5d74-11eb-21a2-c9896abe4b77
md"""
## Check
"""

# ╔═╡ 0b6428b6-5d7b-11eb-3912-458db4e9fae2
df = DataFrame(
	exp=exposure_times,
	r=means[1, :],
	g=means[2, :],
	b=means[3, :],
)

# ╔═╡ 50dabc98-5d7b-11eb-2c4d-bbc60a9d17f4
reg_r = lm(@formula(r ~ exp), df)

# ╔═╡ 97e083a0-5d7b-11eb-06c9-6f6cbaf16341
reg_g = lm(@formula(g ~ exp), df)

# ╔═╡ 9ddb26e8-5d7b-11eb-201e-67eb8c93e662
reg_b = lm(@formula(b ~ exp), df)

# ╔═╡ 2de88186-5d74-11eb-10a2-8755d89d407c
begin
	scatter(
		exposure_times,
		[means[1, :], means[2, :], means[3, :]],
		labels=["r" "g" "b"],
		xlabel="exposure time (s)",
		ylabel="channel mean",
		seriescolor=["red" "green" "blue"],
		legend=:bottomright,
	)
	plot!(
		exposure_times,
		[predict(reg_r), predict(reg_g), predict(reg_b)],
		seriescolor=["red" "green" "blue"],
		labels=false,
	)
end

# ╔═╡ Cell order:
# ╟─33d0c8d2-5d70-11eb-3fd4-c1c40ec2d492
# ╟─3b7b497c-5d70-11eb-187e-f5b8712112ba
# ╠═1c1f8ff4-5d6e-11eb-1252-53826a751284
# ╟─426ddea2-5d70-11eb-0a2b-d72b1cf13e4b
# ╠═7e2e559a-5d6e-11eb-063e-83b2eabe9dcb
# ╟─4ae6869c-5d70-11eb-2368-2383e580b01e
# ╠═9b7b3a00-5d6e-11eb-3181-c3bdf70b5c16
# ╠═c9783106-5d6e-11eb-2433-f51692f7dd8f
# ╟─58885640-5d70-11eb-2932-255058995960
# ╠═fb80bc84-5d70-11eb-1d1f-158ac70f781c
# ╠═0add8372-5d71-11eb-2332-7903a219a078
# ╠═c8fb8adc-5d70-11eb-34e2-a152a7468ba6
# ╠═3bcdefee-5d73-11eb-2853-d95f43a59b07
# ╠═6ee64584-5d73-11eb-09b4-61d7a70f9e70
# ╟─24147688-5d74-11eb-21a2-c9896abe4b77
# ╠═0b6428b6-5d7b-11eb-3912-458db4e9fae2
# ╠═50dabc98-5d7b-11eb-2c4d-bbc60a9d17f4
# ╠═97e083a0-5d7b-11eb-06c9-6f6cbaf16341
# ╠═9ddb26e8-5d7b-11eb-201e-67eb8c93e662
# ╠═2de88186-5d74-11eb-10a2-8755d89d407c
