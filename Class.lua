Object = { __name = "Object" }

function Object:init(...) end

function Object:super(class)
	local obj = self
	return setmetatable({ }, { __index = function(t, k)
		return function(...)
			while class do
				local method = class[k]
				if method then
					return method(obj, ...)
				end
				class = class.__super
			end
		end
	end })
end
function Object:createTable()
	local obj = self
	local class = obj:getClass()
	return setmetatable({ }, { __index = function(t, k)
		return function(...)
			local method = class[k]
			return method(obj, ...)
		end
	end })
end

function Object:getSuper()
	return rawget(self:getClass(), "__super")
end

function Object:getClass()
	return rawget(self, "__class")
end

function Object:instanceof(targetType)
	local objectType = self:getClass()
	while objectType do
		if targetType == objectType then
			return true
		end
		objectType = objectType:getSuper()
	end
	return false
end

function Object:toString()
	return self:getClass():getName().." ("..tostring(self):sub(8, -1)..")"
end

function Object:extend(obj)
	self.__index = self -- This is a metatable

	local obj = obj or {}
	obj.__super = self
	local obj = setmetatable(obj, self)
	return obj
end

Class = Object:extend({__name = "Class"})
function Class:new(...)
	local instance = { __class = self }
	self:extend(instance)
	instance:init(...)
	return instance
end

function Class:getName(name)
	return self.__name
end
function Class:subClass(name)
	local instance = { }
	instance.__name = name

	return self:extend(instance)
end