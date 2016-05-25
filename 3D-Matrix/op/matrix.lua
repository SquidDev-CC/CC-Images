local function multiply4(l, r)
	local l_1_1=l[1]
	local l_2_1=l[2]
	local l_3_1=l[3]
	local l_4_1=l[4]
	local l_1_2=l[5]
	local l_2_2=l[6]
	local l_3_2=l[7]
	local l_4_2=l[8]
	local l_1_3=l[9]
	local l_2_3=l[10]
	local l_3_3=l[11]
	local l_4_3=l[12]
	local l_1_4=l[13]
	local l_2_4=l[14]
	local l_3_4=l[15]
	local l_4_4=l[16]
	local r_1_1=r[1]
	local r_2_1=r[2]
	local r_3_1=r[3]
	local r_4_1=r[4]
	local r_1_2=r[5]
	local r_2_2=r[6]
	local r_3_2=r[7]
	local r_4_2=r[8]
	local r_1_3=r[9]
	local r_2_3=r[10]
	local r_3_3=r[11]
	local r_4_3=r[12]
	local r_1_4=r[13]
	local r_2_4=r[14]
	local r_3_4=r[15]
	local r_4_4=r[16]
	return {
		l_1_1*r_1_1 + l_1_2*r_2_1 + l_1_3*r_3_1 + l_1_4*r_4_1,
		l_2_1*r_1_1 + l_2_2*r_2_1 + l_2_3*r_3_1 + l_2_4*r_4_1,
		l_3_1*r_1_1 + l_3_2*r_2_1 + l_3_3*r_3_1 + l_3_4*r_4_1,
		l_4_1*r_1_1 + l_4_2*r_2_1 + l_4_3*r_3_1 + l_4_4*r_4_1,
		l_1_1*r_1_2 + l_1_2*r_2_2 + l_1_3*r_3_2 + l_1_4*r_4_2,
		l_2_1*r_1_2 + l_2_2*r_2_2 + l_2_3*r_3_2 + l_2_4*r_4_2,
		l_3_1*r_1_2 + l_3_2*r_2_2 + l_3_3*r_3_2 + l_3_4*r_4_2,
		l_4_1*r_1_2 + l_4_2*r_2_2 + l_4_3*r_3_2 + l_4_4*r_4_2,
		l_1_1*r_1_3 + l_1_2*r_2_3 + l_1_3*r_3_3 + l_1_4*r_4_3,
		l_2_1*r_1_3 + l_2_2*r_2_3 + l_2_3*r_3_3 + l_2_4*r_4_3,
		l_3_1*r_1_3 + l_3_2*r_2_3 + l_3_3*r_3_3 + l_3_4*r_4_3,
		l_4_1*r_1_3 + l_4_2*r_2_3 + l_4_3*r_3_3 + l_4_4*r_4_3,
		l_1_1*r_1_4 + l_1_2*r_2_4 + l_1_3*r_3_4 + l_1_4*r_4_4,
		l_2_1*r_1_4 + l_2_2*r_2_4 + l_2_3*r_3_4 + l_2_4*r_4_4,
		l_3_1*r_1_4 + l_3_2*r_2_4 + l_3_3*r_3_4 + l_3_4*r_4_4,
		l_4_1*r_1_4 + l_4_2*r_2_4 + l_4_3*r_3_4 + l_4_4*r_4_4,
	}
end

local function multiply1(l, r)
	local l_1_1=l[1]
	local l_2_1=l[2]
	local l_3_1=l[3]
	local l_4_1=l[4]
	local l_1_2=l[5]
	local l_2_2=l[6]
	local l_3_2=l[7]
	local l_4_2=l[8]
	local l_1_3=l[9]
	local l_2_3=l[10]
	local l_3_3=l[11]
	local l_4_3=l[12]
	local l_1_4=l[13]
	local l_2_4=l[14]
	local l_3_4=l[15]
	local l_4_4=l[16]
	local r_1_1=r[1]
	local r_2_1=r[2]
	local r_3_1=r[3]
	local r_4_1=r[4]
	return {
		l_1_1*r_1_1 + l_1_2*r_2_1 + l_1_3*r_3_1 + l_1_4*r_4_1,
		l_2_1*r_1_1 + l_2_2*r_2_1 + l_2_3*r_3_1 + l_2_4*r_4_1,
		l_3_1*r_1_1 + l_3_2*r_2_1 + l_3_3*r_3_1 + l_3_4*r_4_1,
		l_4_1*r_1_1 + l_4_2*r_2_1 + l_4_3*r_3_1 + l_4_4*r_4_1,
	}
end


local select = select
local function compose(...)
	local result, items = ..., {select(2, ...)}
	for i = 1, #items do
		result = multiply4(result, items[i])
	end

	return result
end

return {
	multiply1 = multiply1,
	multiply4 = multiply4,
	compose = compose,
}
