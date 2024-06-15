/// @func Assert(_expr, _error)
///
/// @desc Shows an error if given expression is false.
///
/// @param {Bool} _expr The expression to check.
/// @param {String} _error The error message to show.
function Assert(_expr, _error)
{
	gml_pragma("forceinline");
	if (!_expr)
	{
		show_error(_error, true);
	}
}

/// @func IComponent()
///
/// @desc Base struct for all entity components.
function IComponent() constructor
{
	/// @var {Struct.CEntity, Asset.GMObject, Undefined} The entity to which is
	/// this component added.
	/// @readonly
	Entity = undefined;

	/// @var {Bool} Whether the component is enabled or not. Defaults to `true`.
	Enabled = true;

	/// @func OnAdd()
	///
	/// @desc A method executed after the component is added to an entity.
	static OnAdd = function () {};

	/// @func OnRemove()
	///
	/// @desc A method executed before the component is removed from an entity.
	static OnRemove = function () {};

	/// @func OnUpdate()
	///
	/// @desc A method executed every time the entity is updated.
	///
	/// @see EntityUpdate
	static OnUpdate = function () {};

	/// @func OnDraw()
	///
	/// @desc A method executed every time the entity is drawn.
	///
	/// @see EntityDraw
	static OnDraw = function () {};

	/// @func OnCleanUp()
	///
	/// @desc A method executed when the entity is destroyed.
	///
	/// @see EntityCleanUp
	static OnCleanUp = function () {};
}

/// @func GetEntityList()
///
/// @desc Retrieves a read-only DS list of all entities.
///
/// @return {Id.DsList} The list of all entities.
function GetEntityList()
{
	static _entities = ds_list_create();
	return _entities;
}

/// @func EntityExists()
///
/// @desc Checks whether the caller is an entity and whether it's not marked for
/// destruction.
///
/// @return {Bool} Returns `true` if the caller is an entity and it's not marked
/// for destruction.
///
/// @see EntityDestroy
///
/// @pure
function EntityExists()
{
	gml_pragma("forceinline");
	return (self[$ "Components"] != undefined && __exists);
}

/// @func EntityDestroy()
///
/// @desc Marks the entity that calls this function for destruction.
///
/// @see EntityExists
/// @see CollectEntities
function EntityDestroy()
{
	gml_pragma("forceinline");
	__exists = false;
}

/// @func CollectEntities()
///
/// @desc Destroys all marked entities.
///
/// @see EntityDestroy
function CollectEntities()
{
	var _entities = GetEntityList();
	for (var i = ds_list_size(_entities) - 1; i >= 0; --i)
	{
		var _entity = _entities[| i];
		if (_entity.__exists)
		{
			continue;
		}

		if (is_struct(_entity))
		{
			_entity.CleanUp(); // Removes self from the list!
			delete _entity;
		}
		else
		{
			instance_destroy(_entity); // Expected to call CleanUp!
		}
	}
}

/// @func EntityHasComponent(_component)
///
/// @desc Checks whether the entity that calls this function has given component.
///
/// @param {Struct.IComponent} _component The component to check for.
///
/// @return {Bool} Returns `true` if the entity has the component.
///
/// @pure
function EntityHasComponent(_component)
{
	gml_pragma("forceinline");
	for (var i = array_length(Components) - 1; i >= 0; --i)
	{
		if (Components[i] == _component)
		{
			return true;
		}
	}
	return false;
}

/// @func EntityHasComponentType(_componentType)
///
/// @desc Checks whether the entity that calls this function has a component of
/// given type.
///
/// @param {Function, Asset.GMScript} _componentType The type of the component.
///
/// @return {Bool} Returns `true` if the entity has a component of the type.
///
/// @pure
function EntityHasComponentType(_componentType)
{
	gml_pragma("forceinline");
	for (var i = array_length(Components) - 1; i >= 0; --i)
	{
		if (is_instanceof(Components[i], _componentType))
		{
			return true;
		}
	}
	return false;
}

/// @func EntityAddComponent(_component)
///
/// @desc Adds a component to the entity that calls this function.
///
/// @param {Struct.IComponent} _component The entity to add.
///
/// @return {Struct.CEntity, Asset.GMObject} Returns `self`.
function EntityAddComponent(_component)
{
	gml_pragma("forceinline");
	Assert(_component.Entity == undefined, "Component is already added to an entity!");
	array_push(Components, _component);
	_component.Entity = self;
	_component.OnAdd();
	return self;
}

/// @func EntityGetComponent(_componentType)
///
/// @desc Retrieves the first found component of given type from the entity that
/// calls this function.
///
/// @param {Function, Asset.GMScript} _componentType The type of the component.
///
/// @return {Struct.IComponent, Undefined} Returns the found component of
/// `undefined` if the entity does not have a component of given type.
///
/// @pure
function EntityGetComponent(_componentType)
{
	gml_pragma("forceinline");
	for (var i = array_length(Components) - 1; i >= 0; --i)
	{
		var _component = Components[i];
		if (is_instanceof(_component, _componentType))
		{
			return _component;
		}
	}
	return undefined;
}

/// @func EntityFindComponents(_componentType)
///
/// @desc Retrieves an array of all components of given type from the entity
/// that calls this function.
///
/// @param {Function, Asset.GMScript} _componentType The type of the component.
///
/// @return {Array<Struct.IComponent>} The array of all found components of
/// given type.
///
/// @pure
function EntityFindComponents(_componentType)
{
	gml_pragma("forceinline");
	var _components = [];
	var _numComponents = array_length(Components);
	for (var i = 0; i < _numComponents; ++i)
	{
		var _component = Components[i];
		if (is_instanceof(_component, _componentType))
		{
			array_push(_components, _component);
		}
	}
	return _components;
}

/// @func EntityRemoveComponent(_component)
///
/// @desc Removes a specific component from the entity that calls this function.
///
/// @param {Struct.IComponent} _component The component to remove.
///
/// @return {Struct.CEntity, Asset.GMObject} Returns `self`.
function EntityRemoveComponent(_component)
{
	gml_pragma("forceinline");
	Assert(_component.Entity == self, "Component is not added to the entity!");
	for (var i = array_length(Components) - 1; i >= 0; --i)
	{
		if (Components[i] == _component)
		{
			array_delete(Components, i, 1);
			_component.OnRemove();
			_component.Entity = undefined;
			break;
		}
	}
	return self;
}

/// @func EntityRemoveComponentType(_componentType[, _limit])
///
/// @desc Removes components of given type from the entity that calls this
/// function.
///
/// @param {Function, Asset.GMScript} _componentType The type of the components
/// to remove.
/// @param {Real} [_limit] Maximum number of components to remove. Defaults to
/// `infinity`.
///
/// @return {Struct.CEntity, Asset.GMObject} Returns `self`.
function EntityRemoveComponentType(_componentType, _limit=infinity)
{
	gml_pragma("forceinline");
	var _numRemoved = 0;
	for (var i = array_length(Components) - 1; i >= 0 && _numRemoved < _limit; --i)
	{
		var _component = Components[i];
		if (is_instanceof(_component, _componentType))
		{
			array_delete(Components, i, 1);
			_component.OnRemove();
			_component.Entity = undefined;
			++_numRemoved;
		}
	}
	return self;
}

/// @func EntityUpdate()
///
/// @desc Updates the entity that calls this function and all its enabled
/// components.
///
/// @return {Struct.CEntity, Asset.GMObject} Returns `self`.
///
/// @see EntityExists
/// @see IComponent.Enabled
/// @see IComponent.OnUpdate
function EntityUpdate()
{
	gml_pragma("forceinline");
	if (__exists)
	{
		var _numComponents = array_length(Components);
		for (var i = 0; i < _numComponents; ++i)
		{
			with (Components[i])
			{
				if (Enabled)
				{
					OnUpdate();
				}
			}
		}
	}
	return self;
}

/// @func EntityDraw()
///
/// @desc Draws the entity that calls this function and all its components.
///
/// @return {Struct.CEntity, Asset.GMObject} Returns `self`.
///
/// @see EntityExists
/// @see IComponent.Enabled
/// @see IComponent.OnDraw
function EntityDraw()
{
	gml_pragma("forceinline");
	if (__exists)
	{
		var _numComponents = array_length(Components);
		for (var i = 0; i < _numComponents; ++i)
		{
			with (Components[i])
			{
				if (Enabled)
				{
					OnDraw();
				}
			}
		}
	}
	return self;
}

/// @func EntityCleanUp()
///
/// @desc Cleans up the entity that calls this function and all its components.
///
/// @see IComponent.CleanUp
function EntityCleanUp()
{
	gml_pragma("forceinline");
	var _numComponents = array_length(Components);
	for (var i = 0; i < _numComponents; ++i)
	{
		Components[i].OnCleanUp();
	}
	// Remove self from the list of entities
	var _entityList = GetEntityList();
	var _pos = ds_list_find_index(_entityList, self);
	ds_list_delete(_entityList, _pos);
}

/// @func MakeEntity()
///
/// @desc Initializes an object instance with all required entity properties.
/// Must be called before using any of the other entity functions on an
/// instance!
function MakeEntity()
{
	Assert(!variable_instance_exists(self, "Components"), "Instance already is an entity!");

	/// @var {Array<Struct.IComponent>} An array of all components added to this
	/// entity.
	/// @readonly
	Components = [];

	/// @var {Bool} If `false` then the entity will be destroyed next time
	/// collect is called.
	/// @private
	__exists = true;

	/// @inheritdoc
	Exists = EntityExists;

	/// @inheritdoc
	HasComponent = EntityHasComponent;

	/// @inheritdoc
	HasComponentType = EntityHasComponentType;

	/// @inheritdoc
	AddComponent = EntityAddComponent;

	/// @inheritdoc
	GetComponent = EntityGetComponent;

	/// @inheritdoc
	FindComponents = EntityFindComponents;

	/// @inheritdoc
	RemoveComponent = EntityRemoveComponent;

	/// @inheritdoc
	RemoveComponentType = EntityRemoveComponentType;

	/// @inheritdoc
	Update = EntityUpdate;

	/// @inheritdoc
	Draw = EntityDraw;

	/// @inheritdoc
	CleanUp = EntityCleanUp;

	/// @inheritdoc
	Destroy = EntityDestroy;

	ds_list_add(GetEntityList(), self);
}

/// @func CEntity()
///
/// @desc Base struct for all struct-based entities.
function CEntity() constructor
{
	/// @var {Array<Struct.IComponent>} An array of all components added to this
	/// entity.
	/// @readonly
	Components = [];

	/// @var {Bool} If `false` then the entity will be destroyed next time
	/// collect is called.
	/// @private
	__exists = true;

	/// @inheritdoc
	static Exists = EntityExists;

	/// @inheritdoc
	static HasComponent = EntityHasComponent;

	/// @inheritdoc
	static HasComponentType = EntityHasComponentType;

	/// @inheritdoc
	static AddComponent = EntityAddComponent;

	/// @inheritdoc
	static GetComponent = EntityGetComponent;

	/// @inheritdoc
	static FindComponents = EntityFindComponents;

	/// @inheritdoc
	static RemoveComponent = EntityRemoveComponent;

	/// @inheritdoc
	static RemoveComponentType = EntityRemoveComponentType;

	/// @inheritdoc
	static Update = EntityUpdate;

	/// @inheritdoc
	static Draw = EntityDraw;

	/// @inheritdoc
	static CleanUp = EntityCleanUp;

	/// @inheritdoc
	static Destroy = EntityDestroy;

	ds_list_add(GetEntityList(), self);
}

/// @func CArrayIterator(_array)
///
/// @desc An array iterator.
///
/// @param {Array} _array The array to iterate through.
function CArrayIterator(_array) constructor
{
	/// @var {Array} The array to iterate through.
	/// @readonly
	Array = _array;

	/// @var {Real} Number of items in the array.
	/// @readonly
	Count = array_length(_array);

	/// @var {Real} The current array index.
	/// @private
	__index = 0;

	/// @func GetNext()
	///
	/// @desc Retrieves the next entry in the array.
	///
	/// @return {Any} The next array entry.
	static GetNext = function ()
	{
		gml_pragma("forceinline");
		Assert(__index < Count, "Iterator out of range!");
		return Array[__index++];
	};
}

/// @func CDsListIterator(_dsList)
///
/// @desc A DS list iterator.
///
/// @param {Id.DsList} _dsList The list to iterate through.
function CDsListIterator(_dsList) constructor
{
	/// @var {Id.DsList} The list to iterate through.
	/// @readonly
	List = _dsList;

	/// @var {Real} Number of items in the list.
	/// @readonly
	Count = ds_list_size(_dsList);

	/// @var {Real} The current list index.
	/// @private
	__index = 0;

	/// @func GetNext()
	///
	/// @desc Retrieves the next entry in the list.
	///
	/// @return {Any} The next list entry.
	static GetNext = function ()
	{
		gml_pragma("forceinline");
		Assert(__index < Count, "Iterator out of range!");
		return List[| __index++];
	};
}

/// @macro Executes a block of code with every component that the enitity has,
/// including ones that are not enabled! The order of components is given by the
/// order in which they were added to the entity.
/// @see IComponent.Enabled
#macro WITH_COMPONENTS \
	with (new CArrayIterator(Components)) \
		repeat (Count) \
			with (GetNext())

/// @macro Executes a block of code with all entities, even those to be
/// destroyed! The order of entities is given by the order in which they were
/// created.
/// @see EntityDestroy
#macro WITH_ENTITIES \
	with (new CDsListIterator(GetEntityList())) \
		repeat (Count) \
			with (GetNext())
