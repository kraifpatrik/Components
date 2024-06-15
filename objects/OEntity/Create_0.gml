// Turn this instance into an entity
MakeEntity();

// Define a custom component
function CCircleComponent(_radius, _outline)
	: IComponent() constructor
{
	Radius = _radius;
	Outline = _outline;

	static OnUpdate = function ()
	{
		if (mouse_check_button(mb_right)
			&& point_distance(Entity.x, Entity.y, mouse_x, mouse_y) < Radius)
		{
			Entity.Destroy();
		}
	};

	static OnDraw = function ()
	{
		draw_circle(Entity.x, Entity.y, Radius, Outline);
	};
}

// Add the component to this entity
AddComponent(new CCircleComponent(16, choose(true, false)));

// Go through all added components and print them to the console
WITH_COMPONENTS
{
	show_debug_message(self);
}
