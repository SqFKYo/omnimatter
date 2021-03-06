local omniston_subcategories = {}
local omniston_recipes = {}
local omniston_technology = {}

local fluid_subcategories = {}
local fluid_recipes = {}
local fluid_technology = {}
local ord={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q"}

local omniFluidCat = "chemistry"
if mods["omnimatter_crystal"] then omniFluidCat = "omniplant" end

local sorting = {
    type = "item-subgroup",
    name = "omniston",
	group = "omnimatter",
	order = "aa",
	}
omniston_subcategories[#omniston_subcategories+1]=sorting

data:extend(omniston_subcategories)

local get_omniston_req=function(lvl)
	local req = {}
	req[#req+1]="omnitech-omnic-acid-hydrolyzation-"..lvl
	if (lvl-1)%omni.fluid_levels_per_tier == 0 then
		if lvl > 1 and omni.fluid_dependency < omni.fluid_levels_per_tier then
			req[#req+1]="omnitech-solvation-omniston-"..(lvl-1)
		end
	else
		req[#req+1]="omnitech-solvation-omniston-"..(lvl-1)
	end
	return req
end


local get_sludge_req=function(lvl)
  local req = {}
  req[#req+1]="omnitech-omnic-acid-hydrolyzation-"..lvl
  if (lvl-1)%omni.fluid_levels_per_tier == 0 then
    req[#req+1]="omnitractor-electric-"..((lvl-1)/omni.fluid_levels_per_tier+1)
    if lvl > 1 and omni.fluid_dependency < omni.fluid_levels_per_tier then
      if data.raw.technology["omnitech-omnisolvent-omnisludge-"..(lvl-1)] then
        req[#req+1]="omnitech-omnisolvent-omnisludge-"..(lvl-1)
      else
        log("no sludge here")
      end
    end
  else
    if data.raw.technology["omnitech-omnisolvent-omnisludge-"..(lvl-1)] then
      req[#req+1]="omnitech-omnisolvent-omnisludge-"..(lvl-1)
    end
  end
  return req
end


local get_distillation_tech_icon=function(item)
    local icon = ""
    if not item.mod then
		icon = "__omnimatter__"
	else
		icon = "__"..item.mod.."__"
	end
	icon=icon.."/graphics/extraction/"..item.fluid.name..".png"
    return icon
end

local get_distillation_req=function(tier,item, level)
	local req = {}
	if omni.fluid_levels>=(tier-1)*omni.fluid_levels_per_tier+level then
		req[#req+1]="omnitech-solvation-omniston-"..(tier-1)*omni.fluid_levels_per_tier+level
	else
		req[#req+1]="omnitech-solvation-omniston-"..omni.fluid_levels
	end
	if (level-1)%omni.fluid_levels_per_tier == 0 then
		if data.raw.technology["omnitractor-electric-"..((level-1)/omni.fluid_levels_per_tier+tier)] then
			req[#req+1]="omnitractor-electric-"..((level-1)/omni.fluid_levels_per_tier+tier)
			if level > 1 and omni.fluid_dependency < omni.fluid_levels_per_tier then
				req[#req+1]="omnitech-distillation-"..item.."-"..(level-1)
			end
		else
			req[#req+1]="omnitech-distillation-"..item.."-"..(level-1)
		end
	else
		req[#req+1]="omnitech-distillation-"..item.."-"..(level-1)
	end
	return req
end

local get_solvation_tech_cost = function(lvl)
	local c = {}
	local size = 2+((lvl-1)-(lvl-1)%omni.fluid_levels_per_tier)/omni.fluid_levels_per_tier
	local length = math.min(size,#omni.sciencepacks)
	for l=1,length do
		local q = 0
		if omni.linear_science then
			q = 1+omni.science_constant*(size-l)
		else
			q=omni.lib.round(math.pow(omni.science_constant,size-l))
		end
		c[#c+1] = {omni.sciencepacks[l],q}
	end
	return c
end

local quant = 24
--log("omnic water disaster")
local cost = OmniGen:create():
		setYield("water"):
		setIngredients({type="fluid",name="omnic-water",amount=360*2}):
		setWaste("omnic-waste"):
		yieldQuant(function(levels,grade) return 360+(grade-1)*360/(levels-1) end ):
		wasteQuant(function(levels,grade) return 360-(grade-1)*360/(levels-1) end)
local omniston = RecChain:create("omnimatter","water-omnitraction"):
		setLocName("recipe-name.water-omnitraction"):
		setIngredients(cost:ingredients()):
		setCategory("omnite-extraction-both"):
		setIcons("water"):
		setMain("water"):
		setResults(cost:results()):
		setSubgroup("omni-fluids"):
		setLevel(omni.fluid_levels):
		setEnergy(function(levels,grade) return 1 end):
		setEnabled(function(levels,grade) return grade == 1 end):
		setTechIcon("omnimatter","water-omnitraction"):
		setTechCost(function(levels,grade) return 25*get_tier_mult(levels,grade,1) end):
		setTechPacks(function(levels,grade) return math.floor((grade-2)/3)+1 end):
		setTechPrereq(function(levels,grade) if mods["omnimatter_water"] and grade == 1 then return "omnitractor-electric-1" else return nil end end):
		setTechTime(15):
		setTechLocName("water-omnitraction"):
		extend()

local cost = OmniGen:create():
		setYield("omniston"):
		setIngredients("omnite"):
		setWaste():
		yieldQuant(function(levels,grade) return omni.omniston_ratio*(120+(grade-1)*120/(levels-1)) end ):
		wasteQuant(function(levels,grade) return math.max(12-extraction_value(levels,grade),0) end)
local omniston = RecChain:create("omnimatter","omniston"):
		setIngredients({{name="pulverized-omnite", amount = quant/3},{name="omnic-acid",type="fluid", amount = 240}}):
		setLocName("fluid-name.omniston"):
		setCategory(omniFluidCat):
		setResults(cost:results()):
		setSubgroup("omni-fluids"):
		setLevel(omni.fluid_levels):
		setEnergy(function(levels,grade) return 5 end):
		setTechPrefix("solvation"):
		setTechIcon("omnimatter","omniston-tech"):
		setTechCost(function(levels,grade) return 25*get_tier_mult(levels,grade,1) end):
		setTechPacks(function(levels,grade) return get_solvation_tech_cost(grade) end):
		setTechPrereq(function(levels,grade) return get_omniston_req(grade)  end):
		setTechTime(15):
		setTechLocName("omniston_solvation"):
		extend()

cost = OmniGen:create():
		setYield("omnisludge"):
		setIngredients("omnite"):
		setWaste():
		yieldQuant(function(levels,grade) return 26/15*(120+(grade-1)*120/(omni.fluid_levels-1)) end ):
		wasteQuant(function(levels,grade) return math.max(12-extraction_value(levels,grade),0) end)
local omnisludge = RecChain:create("omnimatter","omnisludge"):
		setLocName("recipe-name.omnisludge"):
		setIngredients({
		{name = "pulverized-stone", amount = quant/2},
		{type="fluid", name="omnic-acid", amount=240}
		}):
		setCategory(omniFluidCat):
		setSubgroup("omni-fluids"):
		setReqAllMods("omnimatter_crystal"):
		setResults(cost:results()):
		setLevel(omni.fluid_levels):
		setEnergy(function(levels,grade) return 3 end):
		setTechPrefix("omnisolvent"):
		setTechIcon("omnimatter","omni-sludge"):
		setTechCost(function(levels,grade) return 25*get_tier_mult(levels,grade,1) end):
		setTechPacks(function(levels,grade) return get_acid_tech_cost(grade) end):
		setTechPrereq(function(levels,grade) return get_sludge_req(grade)  end):
		setTechLocName("omnisludge"):
		setTechTime(15):
		extend()


local get_distillation_icon = function(fluid,tier)
    local ic = {}
    if fluid.icons then
        for _ , icon in pairs(fluid.icons) do
            ic[#ic+1] = icon
        end
    else
        ic[#ic+1] = {icon = fluid.icon}
    end
    --ic[#ic+1] = {icon = "__omnimatter__/graphics/icons/extraction-"..tier..".png"}
    return ic

end

for _,tier in pairs(omnifluid) do
	for _, fluid in pairs(tier) do
		cost = OmniGen:create():
			setYield(fluid.name):
			setIngredients("omnite"):
			setWaste("omnic-waste"):
			yieldQuant(function(levels,grade) return fluid.ratio*(120+120*(grade-1)/(levels-1)) end ):
			wasteQuant(function(levels,grade) return 240-fluid.ratio*(120+120*(grade-1)/(levels-1)) end)
		local thingy = RecChain:create("omnimatter","distillation-"..fluid.name):
			setLocName("omnifluid_distillation","fluid-name."..fluid.name):
			setIngredients({
			{type="fluid", name="omniston", amount=240}
			}):
			setCategory(omniFluidCat):
			setSubgroup("omni-fluids"):
			setLevel(omni.fluid_levels):
			setIcons(fluid.name):
			setResults(cost:results()):
			setEnergy(function(levels,grade) return 5 end):
			setTechIcon(fluid.mod or "omnimatter",fluid.name):
			setTechCost(function(levels,grade) return 25*get_tier_mult(levels,grade,1) end):
			setTechPacks(function(levels,grade) return get_acid_tech_cost(grade) end):
			setTechPrereq(function(levels,grade) return get_distillation_req(fluid.tier,fluid.name, grade)  end):
			setTechLocName("omnistillation",{"fluid-name."..fluid.name}):
			setTechTime(15):
			extend()

	end
end
