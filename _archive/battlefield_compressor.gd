# BattlefieldCompressor.gd
extends Node


static func uncompress_map_data(compressed_map_data: String, forced: bool = false) -> Array[CellResource]:

	var cell_resources : Array[CellResource] = []

	var data_len : int = compressed_map_data.length()
	var cell_index : int = 0
	var pos : int = 0

	while pos < data_len:
		var cell_resource: CellResource = uncompress_cell(compressed_map_data.substr(pos, 10), forced, 0)
		cell_resource.num = cell_index
		print("[BattlefieldCompressor]: cell_resource.num = " + str(cell_resource.num))
		cell_resources.append(cell_resource)

		cell_index += 1
		pos += 10

	return cell_resources


static func uncompress_cell(compressed_cell_data: String, forced := false, n_permanent_level := 0) -> CellResource:
	var cell_resource = CellResource.new()

	var chars : PackedStringArray = compressed_cell_data.split("")
	var codes : Array = []

	for i in range(chars.size()):
		codes.append(Compressor._self._hash_codes[chars[i]])

	cell_resource.is_active = ((codes[0] & 0x20) >> 5) == 1

	if cell_resource.is_active or forced:
		cell_resource.nPermanentLevel = int(n_permanent_level)
		cell_resource.is_lineOfSight = (codes[0] & 1) == 1

		cell_resource.layerGroundRot = (codes[1] & 0x30) >> 4
		cell_resource.groundLevel = codes[1] & 0x0F

		cell_resource.movement = (codes[2] & 0x38) >> 3
		cell_resource.layerGroundNum = (
			((codes[0] & 0x18) << 6)
			+ ((codes[2] & 7) << 6)
			+ codes[3]
		)

		cell_resource.groundSlope = (codes[4] & 0x3C) >> 2
		cell_resource.is_layerGroundFlip = ((codes[4] & 2) >> 1) == 1

		cell_resource.layerObject1Num = (
			((codes[0] & 4) << 11)
			+ ((codes[4] & 1) << 12)
			+ (codes[5] << 6)
			+ codes[6]
		)

		cell_resource.layerObject1Rot = (codes[7] & 0x30) >> 4
		cell_resource.is_layerObject1Flip = ((codes[7] & 8) >> 3) == 1
		cell_resource.is_layerObject2Flip = ((codes[7] & 4) >> 2) == 1
		cell_resource.is_layerObject2Interactive = ((codes[7] & 2) >> 1) == 1

		cell_resource.layerObject2Num = (
			((codes[0] & 2) << 12)
			+ ((codes[7] & 1) << 12)
			+ (codes[8] << 6)
			+ codes[9]
		)

		cell_resource.layerObjectExternal = ""
		cell_resource.is_layerObjectExternalInteractive = false

	return cell_resource


# static func compress_map(gofus_map) -> String:
# 	if gofus_map == null:
# 		return ""

# 	var result := []
# 	for cell in gofus_map.data:
# 		result.append(compress_cell(cell))

# 	return "".join(result)


# static func compress_cell(cell_resource) -> String:
# 	var data := [0,0,0,0,0,0,0,0,0,0]

# 	data[0] = (int(cell_resource.active) << 5)
# 	data[0] |= int(cell_resource.lineOfSight)
# 	data[0] |= (cell_resource.layerGroundNum & 0x0600) >> 6
# 	data[0] |= (cell_resource.layerObject1Num & 0x2000) >> 11
# 	data[0] |= (cell_resource.layerObject2Num & 0x2000) >> 12

# 	data[1] = (cell_resource.layerGroundRot & 3) << 4
# 	data[1] |= cell_resource.groundLevel & 0x0F

# 	data[2] = (cell_resource.movement & 7) << 3
# 	data[2] |= (cell_resource.layerGroundNum >> 6) & 7

# 	data[3] = cell_resource.layerGroundNum & 0x3F

# 	data[4] = (cell_resource.groundSlope & 0x0F) << 2
# 	data[4] |= int(cell_resource.layerGroundFlip) << 1
# 	data[4] |= (cell_resource.layerObject1Num >> 12) & 1

# 	data[5] = (cell_resource.layerObject1Num >> 6) & 0x3F
# 	data[6] = cell_resource.layerObject1Num & 0x3F

# 	data[7] = (cell_resource.layerObject1Rot & 3) << 4
# 	data[7] |= int(cell_resource.layerObject1Flip) << 3
# 	data[7] |= int(cell_resource.layerObject2Flip) << 2
# 	data[7] |= int(cell_resource.layerObject2Interactive) << 1
# 	data[7] |= (cell_resource.layerObject2Num >> 12) & 1

# 	data[8] = (cell_resource.layerObject2Num >> 6) & 0x3F
# 	data[9] = cell_resource.layerObject2Num & 0x3F

# 	for i in range(data.size()):
# 		data[i] = Compressor.encode64(data[i])

# 	return "".join(data)
