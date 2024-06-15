// Print all existing entities to the console
WITH_ENTITIES
{
	if (Exists())
	{
		show_debug_message(self);
	}
}
