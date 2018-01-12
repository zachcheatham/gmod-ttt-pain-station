
AddCSLuaFile()

SWEP.HoldType = "normal"

if CLIENT then
	LANG.AddToLanguage("english", "pain_station_help", "Use Mouse 1 or 2 to place the Pain Station.")


	SWEP.PrintName = "Pain Station"
	SWEP.Slot = 7

	SWEP.ViewModelFOV = 10

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "An explosive disguised as a Health Station.\nPlayers will explode when they attempt to use it.\n\nIf a Traitor uses it, the Pain Station will\nlose \"health\"."
	};

	SWEP.Icon = "VGUI/ttt/icon_eis_pain_station"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props/cs_office/microwave.mdl"

SWEP.DrawCrosshair = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo	= "none"
SWEP.Secondary.Delay = 1.0

SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true
SWEP.WeaponID = AMMO_PAINSTATION

SWEP.AllowDrop = false

SWEP.NoSights = true

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:HealthDrop()
end
function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	self:HealthDrop()
end

local throwsound = Sound("Weapon_SLAM.SatchelThrow")

function SWEP:HealthDrop()
	if SERVER then
		local ply = self.Owner
		if not IsValid(ply) then return end

		if self.Planted then return end

		local vsrc = ply:GetShootPos()
		local vang = ply:GetAimVector()
		local vvel = ply:GetVelocity()

		local vthrow = vvel + vang * 200

		local health = ents.Create("ttt_pain_station")
		if IsValid(health) then
			health:SetPos(vsrc + vang * 10)
			health:Spawn()

			health:SetPlacer(ply)
			health:PhysWake()

			local phys = health:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity(vthrow)
			end

			self:Remove()
			self.Planted = true
		end
	end

	self:EmitSound(throwsound)
end

function SWEP:Reload()
	return false
end

function SWEP:OnRemove()
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
		RunConsoleCommand("lastinv")
	end
end

if CLIENT then
	function SWEP:Initialize()
		self:AddHUDHelp("pain_station_help", nil, true)

		return self.BaseClass.Initialize(self)
	end
end

function SWEP:Deploy()
	if SERVER and IsValid(self.Owner) then
		self.Owner:DrawViewModel(false)
	end
	return true
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()

end
