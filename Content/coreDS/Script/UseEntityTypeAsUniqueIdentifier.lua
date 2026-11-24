
require("__concatenateEntityType")

function UseEntityTypeAsUniqueIdentifier(value)
	-- Available variables
	-- DSimLocal.Category
	-- DSimLocal.CountryCode
	-- DSimLocal.Domain.Category
	-- DSimLocal.Domain.CountryCode
	-- DSimLocal.Domain.DomainDiscriminant
	-- DSimLocal.EntityKind
	-- DSimLocal.Extra
	-- DSimLocal.On Data Received
	-- DSimLocal.Specific
	-- DSimLocal.Subcategory

	local newvars = CVariant:new()
	newvars['ObjectClassSelector']:set(__concatenateEntityType(value))
	addNewVariables(newvars)
end
