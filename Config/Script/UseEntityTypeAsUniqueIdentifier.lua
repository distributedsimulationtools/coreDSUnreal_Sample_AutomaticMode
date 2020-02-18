
require("__concatenateEntityType")

function UseEntityTypeAsUniqueIdentifier()
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

	DSimLocal.UniqueIdentifier = __concatenateEntityType(DSimLocal)
end
