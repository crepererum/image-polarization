### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ c137751e-5e57-11eb-0a79-eb0f5d95fc0e
begin
	using Colors
	using FileIO
	using Images
	using Plots
	using Statistics
end

# ╔═╡ 9ba20222-5e57-11eb-1b92-159e51b073c3
md"""
# Filter Absorption
"""

# ╔═╡ fbdb2708-5e58-11eb-055a-5d502f6335e1
md"""
## References

- [Wikipedia: Polarizer](https://en.wikipedia.org/wiki/Polarizer)
"""

# ╔═╡ af328738-5e57-11eb-147c-c995a3f08ea1
md"""
## Setup
"""

# ╔═╡ de219d60-5e57-11eb-2ee9-39772a16514b
md"""
## Input
"""

# ╔═╡ e59c77c2-5e57-11eb-1b81-fb82afbbc27b
file_nofilter = "02_absorption/nofilter_converted.tif"

# ╔═╡ f8a4886e-5e57-11eb-151d-471e1d915bf4
file_linearfilter = "02_absorption/linearfilter_converted.tif"

# ╔═╡ acee3b76-5e62-11eb-2031-bb5bcda79732
file_circularfilter = "02_absorption/circularfilter_converted.tif"

# ╔═╡ 0ba0ec8c-5e58-11eb-0dd6-137cc719e780
md"""
## Image Data
"""

# ╔═╡ 1125dfa0-5e58-11eb-0f79-f107131bea4b
const PixelType = RGB{Float64}

# ╔═╡ 18456f94-5e58-11eb-1a02-13bf686d4ace
const ImageType = Array{PixelType, 2}

# ╔═╡ 1e6db7dc-5e58-11eb-11cf-e7cee5e265fe
function load_image(fname::String)::ImageType
	img = load(fname)
	PixelType.(img)
end

# ╔═╡ 26587928-5e58-11eb-2bea-bf164bdc823b
function channel_mean(img::ImageType)::Array{Float64}
	dropdims(mean(channelview(img), dims=(2, 3)); dims=(2, 3))
end

# ╔═╡ 2ca6bbf0-5e58-11eb-1092-9535d09556a0
mean_nofilter = channel_mean(load_image(file_nofilter))

# ╔═╡ 4ad7f4e0-5e58-11eb-3900-df07a3c43415
mean_linearfilter = channel_mean(load_image(file_linearfilter))

# ╔═╡ b945effe-5e62-11eb-105f-89ad52e4ce82
mean_circularfilter = channel_mean(load_image(file_circularfilter))

# ╔═╡ 58d6cf80-5e58-11eb-144f-3daf3fa11355
md"""
## Absorption Calculation
"""

# ╔═╡ 74297148-5e58-11eb-3382-07791e32d9b8
absorption_factor_linear = mean_linearfilter ./ mean_nofilter

# ╔═╡ d15e24a8-5e62-11eb-2ff1-39d4e20aba1d
absorption_factor_circular = mean_circularfilter ./ mean_nofilter

# ╔═╡ 86c30b86-5e58-11eb-00e3-6548331df80e
md"""
## Check

The "with filter" case must have less light than the "no filter" case, resulting in a absorption factor less than 1:
"""

# ╔═╡ 8ffb01b6-5e58-11eb-3e80-2df3fb9f1e9b
all(absorption_factor_linear .< 1.0)

# ╔═╡ e2a405f2-5e62-11eb-1836-45597bd87f5d
all(absorption_factor_circular .< 1.0)

# ╔═╡ eb8bd0d2-5e58-11eb-33f6-9989bf7a3892
md"""
Even stronger, the irradiance after a linear filter for polarized light of a relative angle $\theta_i$ and an irradiance of $I_0$ is:

$I = I_0 \cos^2 \theta_i$

So for all possible inputs angles this is:

$\int_0^\pi \frac{I_0 \cos^2\theta_i}{\pi} d\theta_i = \frac{I_0}{\pi} \int_0^\pi \cos^2\theta_id\theta_i = \frac{I_0}{\pi} \frac{\pi}{2} = \frac{I_0}{2}$

Therefore the absorption factor should be less than 0.5 for all channels (or equal to 0.5 for a perfect filter):
"""

# ╔═╡ 8ce10622-5e64-11eb-3d7b-6bb9c5665be3
absorption_factor_ideal = 0.5

# ╔═╡ b1b7d4fa-5e58-11eb-3f71-654821ffdf9c
all(absorption_factor_linear .< absorption_factor_ideal)

# ╔═╡ a8e887fe-5e60-11eb-1956-a3939b16c4f6
md"""
Finally, let's see if the two images really have a linear relationship:
"""

# ╔═╡ 5e49b586-5e5b-11eb-02ff-eb4c5266d007
function relative_delta(a, b)
	replace!(abs.(a .- b) ./ max.(a, b), NaN=>0.0)
end

# ╔═╡ 5e03ca1a-5e5a-11eb-0860-5f901bf61f65
delta_image_linear = colorview(
	PixelType,
	relative_delta(
		channelview(load_image(file_nofilter)) .* absorption_factor_linear,
		channelview(load_image(file_linearfilter)),
	),
)

# ╔═╡ 0d1a93f0-5e63-11eb-0b87-c3f2ada4cbd3
delta_image_circular = colorview(
	PixelType,
	relative_delta(
		channelview(load_image(file_nofilter)) .* absorption_factor_circular,
		channelview(load_image(file_circularfilter)),
	),
)

# ╔═╡ 4e4cd844-5e63-11eb-2189-512f845b9f15
function plot_image_histogram(img)
	n_bins = 10
	edges_r, counts_r = imhist(channelview(img)[1, :, :], n_bins, 0.0, 1.0)
	edges_g, counts_g = imhist(channelview(img)[2, :, :], n_bins, 0.0, 1.0)
	edges_b, counts_b = imhist(channelview(img)[3, :, :], n_bins, 0.0, 1.0)
	bar(
		[edges_r, edges_g, edges_b],
		[counts_r[1:end-1], counts_g[1:end-1], counts_b[1:end-1]],
		labels=["red" "green" "blue"],
		xlabel="relative delta",
		ylabel="count",
		bar_edges=true,
		seriescolor=["red" "green" "blue"],
		layout=(3, 1),
	)
end

# ╔═╡ 6bc6ee12-5e63-11eb-2d46-ade03a4052ba
plot_image_histogram(delta_image_linear)

# ╔═╡ 83e77638-5e63-11eb-222c-755d79a28261
plot_image_histogram(delta_image_circular)

# ╔═╡ 464b9c0e-5e64-11eb-3612-13183e2351ed
md"""
## Filter Correction

To correct the filter to an "ideal filter", the linear and circular filtered images have to be pre-multiplied with the following factors:
"""

# ╔═╡ 6fc8f1d0-5e64-11eb-0d69-0b02a785c2a6
correction_linear = absorption_factor_ideal ./ absorption_factor_linear

# ╔═╡ 836095f4-5e64-11eb-30d6-c9b55bf7c443
correction_circular = absorption_factor_ideal ./ absorption_factor_circular

# ╔═╡ Cell order:
# ╟─9ba20222-5e57-11eb-1b92-159e51b073c3
# ╟─fbdb2708-5e58-11eb-055a-5d502f6335e1
# ╟─af328738-5e57-11eb-147c-c995a3f08ea1
# ╠═c137751e-5e57-11eb-0a79-eb0f5d95fc0e
# ╟─de219d60-5e57-11eb-2ee9-39772a16514b
# ╠═e59c77c2-5e57-11eb-1b81-fb82afbbc27b
# ╠═f8a4886e-5e57-11eb-151d-471e1d915bf4
# ╠═acee3b76-5e62-11eb-2031-bb5bcda79732
# ╟─0ba0ec8c-5e58-11eb-0dd6-137cc719e780
# ╠═1125dfa0-5e58-11eb-0f79-f107131bea4b
# ╠═18456f94-5e58-11eb-1a02-13bf686d4ace
# ╠═1e6db7dc-5e58-11eb-11cf-e7cee5e265fe
# ╠═26587928-5e58-11eb-2bea-bf164bdc823b
# ╠═2ca6bbf0-5e58-11eb-1092-9535d09556a0
# ╠═4ad7f4e0-5e58-11eb-3900-df07a3c43415
# ╠═b945effe-5e62-11eb-105f-89ad52e4ce82
# ╟─58d6cf80-5e58-11eb-144f-3daf3fa11355
# ╠═74297148-5e58-11eb-3382-07791e32d9b8
# ╠═d15e24a8-5e62-11eb-2ff1-39d4e20aba1d
# ╟─86c30b86-5e58-11eb-00e3-6548331df80e
# ╠═8ffb01b6-5e58-11eb-3e80-2df3fb9f1e9b
# ╠═e2a405f2-5e62-11eb-1836-45597bd87f5d
# ╟─eb8bd0d2-5e58-11eb-33f6-9989bf7a3892
# ╠═8ce10622-5e64-11eb-3d7b-6bb9c5665be3
# ╠═b1b7d4fa-5e58-11eb-3f71-654821ffdf9c
# ╟─a8e887fe-5e60-11eb-1956-a3939b16c4f6
# ╠═5e49b586-5e5b-11eb-02ff-eb4c5266d007
# ╠═5e03ca1a-5e5a-11eb-0860-5f901bf61f65
# ╠═0d1a93f0-5e63-11eb-0b87-c3f2ada4cbd3
# ╠═4e4cd844-5e63-11eb-2189-512f845b9f15
# ╠═6bc6ee12-5e63-11eb-2d46-ade03a4052ba
# ╠═83e77638-5e63-11eb-222c-755d79a28261
# ╟─464b9c0e-5e64-11eb-3612-13183e2351ed
# ╠═6fc8f1d0-5e64-11eb-0d69-0b02a785c2a6
# ╠═836095f4-5e64-11eb-30d6-c9b55bf7c443
