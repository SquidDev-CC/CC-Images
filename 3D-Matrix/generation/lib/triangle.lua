local transI_1, dataI_1, transI_2, dataI_2, transI_3, dataI_3
if index == 1 then
	transI_1, dataI_1, transI_2, dataI_1, transI_3, dataI_3 = trans_1, data_1, trans_2, data_2, trans_3, dataI_3
elseif index == 2 then
	transI_1, dataI_1, transI_2, dataI_1, transI_3, dataI_3 = trans_2, data_2, trans_3, data_3, trans_1, dataI_1
else
	transI_1, dataI_1, transI_2, dataI_1, transI_3, dataI_3 = trans_3, data_3, trans_1, data_1, trans_2, dataI_2
end

local t1 = func(transI_1, transI_2)
local transT_1, dataT_1 = interpolate(transI_1, transI_2, t1)

local t2 = func(transI_1, transI_3)
local transT_2, dataT_2 = interpolate(transI_1, transI_3, t2)

if count == 0  then
	-- One point outside. 1 = the point outside

	-- Temp1, Ver2, Ver3
	drawTriangle(transT_1, dataT_1, transI_2, dataI_2, transI_3, dataI_3, $1 direction + 1)
	-- Temp2, Temp1, Ver3
	drawTriangle(transT_2, dataT_2, transT_1, dataT_1, transI_3, dataI_3, $1 direction + 1)
 else
	-- Two points outside: 1 = the point inside
	-- Ver1, Temp2, Temp3
	return drawTriangle(transI_1, dataI_1, transT_1, dataT_1, transT_2, daaT_2, $1 direction + 1)
end
