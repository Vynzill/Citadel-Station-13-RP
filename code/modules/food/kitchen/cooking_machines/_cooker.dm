/obj/machinery/appliance/cooker
	var/temperature = T20C
	var/min_temp = 80 + T0C	//Minimum temperature to do any cooking
	var/optimal_temp = 200 + T0C	//Temperature at which we have 100% efficiency. efficiency is lowered on either side of this
	var/optimal_power = 0.1//cooking power at 100%

	var/loss = 1	//Temp lost per proc when equalising
	var/resistance = 320000	//Resistance to heating. combines with active power usage to determine how long heating takes

	var/light_x = 0
	var/light_y = 0
	cooking_power = 0

/obj/machinery/appliance/cooker/examine(var/mob/user)
	. = ..()
	if (.)	//no need to duplicate adjacency check
		if (!stat)
			if (temperature < min_temp)
				to_chat(user, span("warning", "\The [src] is still heating up and is too cold to cook anything yet."))
			else
				to_chat(user, span("notice", "It is running at [round(get_efficiency(), 0.1)]% efficiency!"))
			to_chat(user, "Temperature: [round(temperature - T0C, 0.1)]C / [round(optimal_temp - T0C, 0.1)]C")
		else
			to_chat(user, span("warning", "It is switched off."))

/obj/machinery/appliance/cooker/list_contents(var/mob/user)
	if (cooking_objs.len)
		var/string = "Contains...</br>"
		var/num = 0
		for (var/a in cooking_objs)
			num++
			var/datum/cooking_item/CI = a
			if (CI && CI.container)
				string += "- [CI.container.label(num)], [report_progress(CI)]</br>"
		to_chat(user, string)
	else
		to_chat(user, span("notice","It is empty."))

/obj/machinery/appliance/cooker/proc/get_efficiency()
	//RefreshParts()
	return (cooking_power / optimal_power) * 100

/obj/machinery/appliance/cooker/New()
	. = ..()
	loss = (active_power_usage / resistance)*0.5
	cooking_objs = list()
	for (var/i = 0, i < max_contents, i++)
		cooking_objs.Add(new /datum/cooking_item/(new container_type(src)))
	cooking = 0

	update_icon() // this probably won't cause issues, but Aurora used SSIcons and queue_icon_update() instead

/obj/machinery/appliance/cooker/update_icon()
	cut_overlays()
	var/image/light
	if (use_power == 2 && !stat)
		light = image(icon, "light_on")
	else
<<<<<<< HEAD
		light = image(icon, "light_off")
	light.pixel_x = light_x
	light.pixel_y = light_y
	add_overlay(light)

/obj/machinery/appliance/cooker/process()
	if (!stat)
		heat_up()
	else
		var/turf/T = get_turf(src)
		if (temperature > T.temperature)
			equalize_temperature()
	..()
=======
		var/failed
		var/overcook_period = max(FLOOR(cook_time/5, 1),1)
		cooking_obj = result
		var/count = overcook_period
		while(1)
			sleep(overcook_period)
			count += overcook_period
			if(!cooking || !result || result.loc != src)
				failed = 1
			else if(prob(burn_chance) || count == cook_time)	//Fail before it has a chance to cook again.
				// You dun goofed.
				qdel(cooking_obj)
				cooking_obj = new /obj/item/weapon/reagent_containers/food/snacks/badrecipe(src)
				// Produce nasty smoke.
				visible_message("<span class='danger'>\The [src] vomits a gout of rancid smoke!</span>")
				var/datum/effect/effect/system/smoke_spread/bad/smoke = new /datum/effect/effect/system/smoke_spread/bad()
				smoke.attach(src)
				smoke.set_up(10, 0, usr.loc)
				smoke.start()
				failed = 1

			if(failed)
				cooking = 0
				icon_state = off_icon
				break

/obj/machinery/cooker/attack_hand(var/mob/user)
>>>>>>> 629eebd... Merge pull request #4555 from VOREStation/upstream-merge-5654

/obj/machinery/appliance/cooker/power_change()
	. = ..()
	update_icon() // this probably won't cause issues, but Aurora used SSIcons and queue_icon_update() instead

/obj/machinery/appliance/cooker/proc/update_cooking_power()
	var/temp_scale = 0
	if(temperature > min_temp)

		temp_scale = (temperature - min_temp) / (optimal_temp - min_temp)
		//If we're between min and optimal this will yield a value in the range 0-1

		if (temp_scale > 1)
			//We're above optimal, efficiency goes down as we pass too much over it
			if (temp_scale >= 2)
				temp_scale = 0
			else
				temp_scale = 1 - (temp_scale - 1)


	cooking_power = optimal_power * temp_scale
	//RefreshParts()

/obj/machinery/appliance/cooker/proc/heat_up()
	if (temperature < optimal_temp)
		if (use_power == 1 && ((optimal_temp - temperature) > 5))
			playsound(src, 'sound/machines/click.ogg', 20, 1)
			use_power = 2.//If we're heating we use the active power
			update_icon()
		temperature += active_power_usage / resistance
		update_cooking_power()
		return 1
	else
		if (use_power == 2)
			use_power = 1
			playsound(src, 'sound/machines/click.ogg', 20, 1)
			update_icon()
		//We're holding steady. temperature falls more slowly
		if (prob(25))
			equalize_temperature()
			return -1

/obj/machinery/appliance/cooker/proc/equalize_temperature()
	temperature -= loss//Temperature will fall somewhat slowly
	update_cooking_power()

//Cookers do differently, they use containers
/obj/machinery/appliance/cooker/has_space(var/obj/item/I)
	if (istype(I, /obj/item/weapon/reagent_containers/cooking_container))
		//Containers can go into an empty slot
		if (cooking_objs.len < max_contents)
			return 1
	else
		//Any food items directly added need an empty container. A slot without a container cant hold food
		for (var/datum/cooking_item/CI in cooking_objs)
			if (CI.container.check_contents() == 0)
				return CI

	return 0

/obj/machinery/appliance/cooker/add_content(var/obj/item/I, var/mob/user)
	var/datum/cooking_item/CI = ..()
	if (CI && CI.combine_target)
		to_chat(user, "\The [I] will be used to make a [selected_option]. Output selection is returned to default for future items.")
		selected_option = null
