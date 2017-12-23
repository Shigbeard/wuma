
local object = {}
local static = {}

object._id = "WUMA_Limit"
static._id = "WUMA_Limit"

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
///////////////////////////////////////////////////////// 
function static:GetID()
	return Limit._id
end
 
function static:GenerateID(usergroup,str)
	if usergroup then
		return string.lower(string.format("%s_%s",usergroup,str))
	else
		return string.lower(str)
	end
end

function static:GenerateHit(str,ply)
	ply:SendLua(string.format([[notification.AddLegacy("You've hit the %s limit!",NOTIFY_ERROR,3)]],str))
	ply:SendLua([[surface.PlaySound("buttons/button10.wav")]])
end

/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////
function object:Construct(tbl)
	self.super("Construct", tbl)

	self.string = tbl.string or nil
	self.limit = tbl.limit or 0
	self.usergroup = tbl.usergroup or nil
	self.exclusive = tbl.exclusive or nil
	
	self.m.origin = tbl.origin or nil
	self.m.parent = tbl.parent or nil
	if isstring(self.m.parent) then self.m.parentid = self.m.parent elseif self.m.parent then self.m.parentid = self.m.parent:SteamID() end
	self.m.count = tbl.count or 0
	self.m.entities = tbl.entities or {}
	self.m.callonempty = tbl.callonempty or {}
	
	--No numeric adv. limits
	if (tonumber(self.string) != nil) then self.string = ":"..self.string..":" end
	
	--Make sure limit and string cannot be the same
	if (self.limit == self.string) then self.limit = self.limit..":" end
	
	--Parse limit
	if (tonumber(self.limit) != nil) then self.limit = tonumber(self.limit) end
	
	if tbl.scope then self:SetScope(tbl.scope) else self.m.scope = "Permanent" end
  
	return obj
end 

function object:__tostring()
	return string.format("Limit [%s][%s/%s]",self:GetString(),tostring(self:GetCount()),tostring(self:Get()))
end
 
function object:__call(ply)
	
end

function object:__eq(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() == that:Get())
	elseif not(tonumber(that) == nil) then
		return (self:Get() == that)
	end
	return false
end

function object:__lt(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() < that:Get())
	elseif not(tonumber(that) == nil) then
		return (self:Get() < that)
	end
	return false
end

function object:__le(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() <= that:Get())
	elseif not(tonumber(that) == nil) then
		return (self:Get() <= that)
	end
	return false
end

function object:Delete()
	--So that no entities point here
	for id, entity in pairs(self.m.entities)  do
		entity:RemoveWUMAParent(entity)
	end
	
	if self.scope then
		self.scope:Delete()
	end
end

function object:Shred()
	if self:IsPersonal() then
		WUMA.RemoveUserLimit(_,self:GetParentID(),self:GetString())
	else
		WUMA.RemoveLimit(_,self:GetUserGroup(),self:GetString())
	end
end

function object:IsPersonal()
	if self.usergroup then return nil else return true end
end
	
function object:CallOnEmpty(id, f)
	if SERVER then
		self.m.callonempty[id] = f
	end
end
	
function object:NotifyEmpty()
	if SERVER then
		for _, f in pairs(self.m.callonempty) do f(self) end
	end	
end
	
function object:Get()
	if self.m.limit then return self.m.limit end
	return self.limit 
end
 
function object:Set(c)
	self.limit = c
end

function object:GetID(short)
	if (not self:GetUserGroup()) or short then
		return string.lower(self.string)
	else
		return string.lower(string.format("%s_%s",self:GetUserGroup(),self:GetString()))
	end
end

function object:GetCount()
	return self.m.count
end

function object:SetCount(c)
	if (c < 0) then c = 0 end
	self.m.count = c
end

function object:GetUserGroup()
	return self.usergroup
end

function object:SetString(str)
	self.string = str
end

function object:IsExclusive()
	return self.exclusive
end

function object:SetExclusive(bool)
	self.exclusive = str
end

function object:InheritEntities(limit)
	self.m.entities = limit.m.entities
	self:SetCount(limit:GetCount())
	
	for id, entity in pairs(self.m.entities) do
		entity:AddWUMAParent(self) 
	end
end

function object:Check(int)
	if self:IsDisabled() then return end
	
	local limit = int or self:Get()

	if istable(limit) then 
		if not limit:IsExclusive() then
			return limit:Check()
		else
			return self:Check(limit:Get()) 
		end
	elseif isstring(limit) and self:GetParent():HasLimit(limit) then
		return self:Check(self:GetParent():GetLimit(limit))
	elseif isstring(limit) then
		return
	end
	
	if (limit < 0) then return true end
	if (limit <= self:GetCount()) then
		self:Hit()
		return false
	end
	
	return true
end

function object:Hit()
	local str = self.print or self.string
	
	self:GetParent():SendLua(string.format([[
			notification.AddLegacy("You've hit the %s limit!",NOTIFY_ERROR,3)
		]],str))
	self:GetParent():SendLua([[surface.PlaySound("buttons/button10.wav")]])
end

function object:DeleteEntity(id)
	self.m.entities[id] = nil
	self:Subtract()
end 

function object:Subtract(c)
	c = tonumber(c) or 1
	self:SetCount(self:GetCount() - c)
	if (self:GetCount() == 0) then self:NotifyEmpty() end
end 

function object:Add(entity)
	if (self.m.entities[entity:GetCreationID()]) then return end

	self:SetCount(self:GetCount() + 1)
	
	local limit = self:Get()
	if isstring(limit) and self:GetParent():HasLimit(limit) then
		self:GetParent():GetLimit(limit):Add(entity) 
	end
	
	entity:AddWUMAParent(self) 
	self.m.entities[entity:GetCreationID()] = entity
end

Limit = UserObject:Inherit(static, object)