---
layout: post
title:  "Measurement groups"
date:   2015-12-01 22:00:00
categories: news
tags: [software, news]
---

What is measurement group?
--------------------------

It's set of array of names to define measurements which are similar to themself in
any way. You are free to set your own groups in `main.cpp` file, like in example below:

```
h->measGroup->addGroup("name_of_group", "meas1,meas2,meas3");
```

Example:

```
h->measGroup->addGroup("temperature", "int_temperature,ext_temperature");
```

All of them describe temperature and are stored in identical unit - degrees.
But it's not required. You can create group with measurements related only
by nature of the system.

```
h->measGroup->addGroup("battery_state", "batt_u,i_gen_batt");
```

In example above battery voltage is related to current which charge them.

```
h->measGroup->addGroup("generator_state", "coil1,i_gen_batt");
```

In example above charging current is related to coil voltage.
