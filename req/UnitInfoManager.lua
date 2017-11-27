UnitInfo = UnitInfo or class()

function UnitInfo:init(unit, u_key, manager)
  self._unit = unit
  self._unit_key = u_key
  self._type = "unknown"
  self._name = u_key
  
  local u_base = unit:base()
  local cm = managers.criminals
  
  self._owner = manager:get_info(u_base.get_owner and u_base:get_owner() or u_base._minion_owner or u_base.kpr_minion_owner_peer_id and cm:character_unit_by_peer_id(u_base.kpr_minion_owner_peer_id))
  if u_base.is_husk_player or u_base.is_local_player then
    self._type = "player"
    self._sub_type = u_base.is_local_player and "local_player" or "remote_player"
    self._peer = unit:network():peer()
    self._name = u_base.is_local_player and managers.network.account:username() or self._peer:name()
    self._level = u_base.is_local_player and managers.experience:current_level() or self._peer:level()
    self._rank = u_base.is_local_player and managers.experience:current_rank() or self._peer:rank()
    self._damage = self._peer._data_damage or 0
    self._kills = self._peer._data_kills or 0
    self._color_id = cm:character_color_id_by_unit(unit)
  elseif HopLib:is_object_of_class(u_base, CopBase) then
    self._type = "npc"
    self._damage = 0
    self._kills = 0
    self._color_id = self._owner and self._owner._color_id or cm:character_color_id_by_unit(unit)
    local gstate = managers.groupai:state()
    if gstate:is_unit_team_AI(unit) then
      self._sub_type = "team_ai"
      self._name = u_base:nick_name()
    elseif gstate._police[u_key] and gstate._police[u_key].is_converted or gstate:is_enemy_converted_to_criminal(unit) then
      self._sub_type = "joker"
      self._name = manager._name_provider:name_by_id(u_base._stats_name or u_base._tweak_table)
      self._nickname = u_base.kpr_minion_owner_peer_id and Keepers:GetJokerNameByPeer(u_base.kpr_minion_owner_peer_id)
      if not self._nickname or self._nickname == "" then
        self._nickname = self._owner and self._owner:nickname() .. "'s " .. self._name
      end
    elseif u_base.char_tweak then
      self._sub_type = HopLib:is_object_of_class(u_base, CivilianBase) and "civilian"
      self._name = manager._name_provider:name_by_id(u_base._stats_name or u_base._tweak_table)
      self._is_special = u_base:char_tweak().priority_shout and true
      self._is_boss = u_base._tweak_table:find("boss") and true
    end
  elseif u_base.thrower_unit then
    self._type = "projectile"
    self._name = manager._name_provider:name_by_id(u_base:get_name_id())
    self._thrower = manager:get_info(u_base:thrower_unit())
  elseif u_base.sentry_gun then
    self._type = "sentry"
    self._name = manager._name_provider:name_by_id(u_base._tweak_table_id)
    self._nickname = self._owner and self._owner:nickname() .. "'s " .. self._name
    self._is_special = u_base._tweak_table_id:find("turret") and true
    self._damage = 0
    self._kills = 0
    self._color_id = self._owner and self._owner._color_id or cm:character_color_id_by_unit(unit)
  end
end

function UnitInfo:user()
  return self._thrower or self
end

function UnitInfo:update_damage(damage, is_kill)
  self._damage = self._damage + damage
  if is_kill then
    self._kills = self._kills + 1
  end
  if self._peer then
    self._peer._data_damage = self._damage
    self._peer._data_kills = self._kills
  end
end

function UnitInfo:nickname()
  return self._nickname or self._name
end

UnitInfoManager = UnitInfoManager or class()

function UnitInfoManager:init(name_provider)
  self._infos = {}
  self._name_provider = name_provider
end

function UnitInfoManager:all_infos()
  return self._infos
end

function UnitInfoManager:name_provider()
  return self._name_provider
end

function UnitInfoManager:_create_info(unit, u_key)
  if not alive(unit) or not u_key then
    return
  end
  local entry = UnitInfo:new(unit, u_key, self)
  self._infos[u_key] = entry
  return entry
end

function UnitInfoManager:get_info(unit)
  local u_key = alive(unit) and unit:key()
  if not u_key then
    return
  end
  return self._infos[u_key] or self:_create_info(unit, u_key)
end

function UnitInfoManager:get_user_info(unit)
  local u_key = alive(unit) and unit:key()
  if not u_key then
    return
  end
  local info = self._infos[u_key] or self:_create_info(unit, u_key)
  return info and info:user()
end

function UnitInfoManager:clear_info(unit, u_key)
  u_key = u_key or alive(unit) and unit:key()
  self._infos[u_key] = nil
end