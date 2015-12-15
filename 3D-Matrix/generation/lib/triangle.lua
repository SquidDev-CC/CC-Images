local transI_1, dataI_1, clipI_1, projI_1, transI_2, dataI_2, clipI_2, projI_2, transI_3, dataI_3, clipI_3, projI_3
if index == 1 then
	transI_1, dataI_1, clipI_1, projI_1 = trans_1, data_1, clip_1, proj_1
	transI_2, dataI_2, clipI_2, projI_2 = trans_2, data_2, clip_2, proj_2
	transI_3, dataI_3, clipI_3, projI_3 = trans_3, data_3, clip_3, proj_3
elseif index == 2 then
	transI_1, dataI_1, clipI_1, projI_1 = trans_2, data_2, clip_2, proj_2
	transI_2, dataI_2, clipI_2, projI_2 = trans_3, data_3, clip_3, proj_3
	transI_3, dataI_3, clipI_3, projI_3 = trans_1, data_1, clip_1, proj_1
else
	transI_1, dataI_1, clipI_1, projI_1 = trans_3, data_3, clip_3, proj_3
	transI_2, dataI_2, clipI_2, projI_2 = trans_1, data_1, clip_1, proj_1
	transI_3, dataI_3, clipI_3, projI_3 = trans_2, data_2, clip_2, proj_2
end

local t1 = func(transI_1, transI_2)
local transT_1, dataT_1 = interpolate(transI_1, dataI_1, transI_2, dataI_2, t1)
local _, clipT_1, projT_1 = clipProject(transT_1)

local t2 = func(transI_1, transI_3)
local transT_2, dataT_2 = interpolate(transI_1, dataI_1, transI_3, dataI_3, t2)
local _, clipT_2, projT_2 = clipProject(transT_2)

if count == 1  then
	print("One point outside: " .. table.concat(transI_1, ", "))
	-- One point outside. 1 = the point outside

	-- Temp1, Ver2, Ver3
	triangle(transT_1, clipT_1, projT_1, dataT_1, transI_2, clipI_2, projI_2, dataI_2, transI_3, clipI_3, projI_3, dataI_3, $1 direction + 1)
	-- Temp2, Temp1, Ver3
	triangle(transT_2, clipT_2, projT_2, dataT_2, transT_1, clipT_1, projT_1, dataT_1, transI_3, clipI_3, projI_3, dataI_3, $1 direction + 1)
 else
 	print("One point inside: " .. table.concat(transI_1, ", "))
	-- Two points outside: 1 = the point inside
	-- Ver1, Temp1, Temp2
	return triangle(transI_1, clipI_1, projI_1, dataI_1, transT_1, clipT_1, projT_1, dataT_1, transT_2, clipT_2, projT_2, dataT_2, $1 direction + 1)
end
