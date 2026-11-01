--!native
--!optimize 2
const byte = string.byte

const function restricted_edit_damerau_levenshtein_distance(
	left: string,
	right: string,
	dist_cutoff: number
): number?
	local left_length = #left
	local right_length = #right
	local shorter_length = math.min(left_length, right_length)
	local longer_length = math.max(left_length, right_length)
	const length_difference = longer_length - shorter_length
	if length_difference > dist_cutoff then
		return nil
	elseif shorter_length == 0 then
		return longer_length
	end

	local first_mismatch_offset: number?
	for offset = 1, shorter_length do
		if byte(left, offset) ~= byte(right, offset) then
			first_mismatch_offset = offset
			break
		end
	end
	if not first_mismatch_offset then
		return length_difference
	end
	const common_prefix_offset = first_mismatch_offset - 1

	local has_suffix_mismatch = false
	for suffix_offset = -1, -shorter_length, -1 do
		if byte(left, suffix_offset) == byte(right, suffix_offset) then
			continue
		end
		has_suffix_mismatch = true
		const delta = suffix_offset + 1
		shorter_length += delta
		longer_length += delta
		if shorter_length == 0 then
			return longer_length
		end
		left_length += delta
		right_length += delta
		break
	end
	if not has_suffix_mismatch then
		shorter_length = common_prefix_offset
		longer_length = common_prefix_offset + length_difference
	end
	if shorter_length <= common_prefix_offset then
		if length_difference > dist_cutoff then
			return nil
		end
		return length_difference
	end
	if dist_cutoff > longer_length then
		dist_cutoff = longer_length
	end

	local shorter_str: string
	local longer_str: string
	if left_length < right_length then
		shorter_str, longer_str = left, right
	else
		shorter_str, longer_str = right, left
	end

	const shorter_window_length = shorter_length - common_prefix_offset

	const longer_window_length = longer_length - common_prefix_offset
	if dist_cutoff > longer_window_length then
		dist_cutoff = longer_window_length
	end

	const last_row_distances, diagonal_distances =
		table.create(longer_window_length, 0), table.create(longer_window_length, 0)

	for column = 1, dist_cutoff do
		last_row_distances[column] = column
	end
	for column = dist_cutoff + 1, longer_window_length do
		last_row_distances[column] = dist_cutoff + 1
	end

	const has_distance_cutoff = dist_cutoff < longer_window_length

	const column_start_offset = dist_cutoff - length_difference
	local first_column, last_column = 1, dist_cutoff

	local shorter_char = byte(shorter_str, common_prefix_offset + 1)
	local cell_distance = 0

	for row = 1, shorter_window_length do
		const row_offset = row - 1

		const previous_shorter_char = shorter_char
		shorter_char = byte(shorter_str, common_prefix_offset + row)

		local left_distance = row_offset
		cell_distance = left_distance + 1

		if row_offset > column_start_offset then
			first_column += 1
		end
		if last_column < longer_window_length then
			last_column += 1
		end

		local next_transposition_distance = if first_column > 1
			then diagonal_distances[first_column - 1]
			else 0

		for column = first_column, last_column do
			const above_distance = cell_distance

			local transposition_distance = next_transposition_distance
			next_transposition_distance = diagonal_distances[column]

			cell_distance = left_distance
			diagonal_distances[column] = cell_distance
			left_distance = last_row_distances[column]

			const longer_char = byte(longer_str, common_prefix_offset + column)

			if shorter_char ~= longer_char then
				if left_distance < cell_distance then
					cell_distance = left_distance
				end
				if above_distance < cell_distance then
					cell_distance = above_distance
				end
				cell_distance += 1

				if
					row > 1
					and column > 1
					and shorter_char == byte(
						longer_str,
						common_prefix_offset + column - 1
					)
					and previous_shorter_char == longer_char
				then
					transposition_distance += 1
					cell_distance = math.min(cell_distance, transposition_distance)
				end
			end

			last_row_distances[column] = cell_distance
		end

		if
			has_distance_cutoff
			and last_row_distances[row_offset + length_difference + 1] > dist_cutoff
		then
			return nil
		end
	end

	if cell_distance > dist_cutoff then
		return nil
	end
	return cell_distance
end

const function restricted_edit_damerau_levenshtein_lookup(
	left: string,
	lookups: {
		read [string]: unknown,
	},
	dist_cutoff: number
): (string?, number)
	local best_str, best_dist

	for right in lookups do
		const right_dist =
			restricted_edit_damerau_levenshtein_distance(left, right, dist_cutoff)

		if not right_dist then
			continue
		end

		if not best_dist or right_dist < best_dist then
			best_dist = right_dist
			best_str = right
		end
	end

	return best_str, best_dist or math.huge
end

return table.freeze({
	restricted_edit_damerau_distance = restricted_edit_damerau_levenshtein_distance,
	restricted_edit_damerau_lookup = restricted_edit_damerau_levenshtein_lookup,
})
