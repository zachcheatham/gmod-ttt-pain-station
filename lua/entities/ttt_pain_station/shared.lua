---- Health dispenser

AddCSLuaFile()

if CLIENT then
	-- this entity can be DNA-sampled so we need some display info
	ENT.Icon = "vgui/ttt/icon_health"
	ENT.PrintName = "hstation_name"

	local GetPTranslation = LANG.GetParamTranslation

	ENT.TargetIDHint = {
		name = "hstation_name",
		hint = "hstation_hint",
		fmt  = function(ent, txt) return GetPTranslation(txt, {usekey = Key("+use", "USE"), num	= ent:GetStoredHealth() or 0 }) end
	};
end

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/microwave.mdl")

--ENT.CanUseKey = true
ENT.CanHavePrints = true
ENT.MaxHeal = 25
ENT.MaxStored = 200
ENT.RechargeRate = 1
ENT.RechargeFreq = 2 -- in seconds

ENT.NextHeal = 0
ENT.HealRate = 1
ENT.HealFreq = 0.2

AccessorFuncDT(ENT, "StoredHealth", "StoredHealth")

AccessorFunc(ENT, "Placer", "Placer")

function ENT:SetupDataTables()
	self:DTVar("Int", 0, "StoredHealth")
end

function ENT:Initialize()
	self:SetModel(self.Model)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)

	local b = 32
	self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	if SERVER then
		self:SetMaxHealth(200)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMass(200)
		end

		self:SetUseType(CONTINUOUS_USE)
	end
	self:SetHealth(200)

	self:SetColor(Color(180, 180, 250, 255))

	self:SetStoredHealth(200)

	self:SetPlacer(nil)

	self.NextHeal = 0

	//self.fingerprints = {}
end


function ENT:AddToStorage(amount)
	self:SetStoredHealth(math.min(self.MaxStored, self:GetStoredHealth() + amount))
end

function ENT:TakeFromStorage(amount)
	-- if we only have 5 healthpts in store, that is the amount we heal
	amount = math.min(amount, self:GetStoredHealth())
	self:SetStoredHealth(math.max(0, self:GetStoredHealth() - amount))
	return amount
end

local healsound = Sound("items/medshot4.wav")
local failsound = Sound("items/medshotno1.wav")

local last_sound_time = 0
function ENT:GiveHealth(ply, max_heal)
	if self:GetStoredHealth() > 0 then
		max_heal = max_heal or self.MaxHeal
		local dmg = ply:GetMaxHealth() - ply:Health()
		if dmg > 0 then
			-- constant clamping, no risks
			local healed = self:TakeFromStorage(math.min(max_heal, dmg))
			local new = math.min(ply:GetMaxHealth(), ply:Health() + healed)

			hook.Run("TTTPlayerUsedHealthStation", ply, self, healed)

			if last_sound_time + 2 < CurTime() then
				self:EmitSound(healsound)
				last_sound_time = CurTime()
			end

			/*if not table.HasValue(self.fingerprints, ply) then
				table.insert(self.fingerprints, ply)
			end*/

			return true
		else
			self:EmitSound(failsound)
		end
	else
		self:EmitSound(failsound)
	end

	return false
end

function ENT:Use(ply)
	if IsValid(ply) and ply:IsPlayer() and ply:IsActive() then
		if ply:IsTraitor() then
			local t = CurTime()
			if t > self.NextHeal then
				local healed = self:GiveHealth(ply, self.HealRate)
				self.NextHeal = t + (self.HealFreq * (healed and 1 or 2))
			end
		else
			local explosion = ents.Create("env_explosion")
			explosion:SetPos(self.Entity:GetPos())
			explosion:SetOwner(self:GetPlacer())
			explosion:Spawn()
			explosion:SetKeyValue("iMagnitude", "120") -- KBz made this shit OP (Used to be 80)
			explosion:Fire("Explode", 0, 0)
			explosion:EmitSound("siege/big_explosion.wav", 500, 500)

			self.Entity:Remove()
		end
	end
end

-- traditional equipment destruction effects
function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)

	self:SetHealth(self:Health() - dmginfo:GetDamage())

	local att = dmginfo:GetAttacker()
	if IsPlayer(att) then
		DamageLog(Format("%s damaged pain station for %d dmg", att:Nick(), dmginfo:GetDamage()))
	end

	if self:Health() < 0 then
		self:Remove()

		util.EquipmentDestroyed(self:GetPos())

		if IsValid(self:GetPlacer()) then
			CustomMsg(self:GetPlacer(), "Your Pain Station has been destroyed!")
		end
	end
end

// Draw the [T] above the pain station
local indicatorMat = Material("vgui/ttt/sprite_traitor")
local indicatorCol = Color(255, 255, 255, 130)
function ENT:Draw()
	self.BaseClass.Draw(self)

	local lp = LocalPlayer()

	if lp:IsTraitor() then
		local dir = lp:GetForward() * -1

		local pos = self:GetPos()
		pos.z = pos.z + 25 // Raise the icon up above

		if lp:IsLineOfSightClear(pos) then
			render.SetMaterial(indicatorMat)
			render.DrawQuadEasy(pos, dir, 8, 8, indicatorCol, 180)
		end
	end
end

if SERVER then
	-- recharge
	local nextcharge = 0
	function ENT:Think()
		if nextcharge < CurTime() then
			self:AddToStorage(self.RechargeRate)
			nextcharge = CurTime() + self.RechargeFreq
		end
	end
end