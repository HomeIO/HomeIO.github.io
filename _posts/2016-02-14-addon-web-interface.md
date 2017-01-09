---
layout: post
title:  "Addons web interface"
date:   2016-02-14 15:00:00
categories: news
tags: [homeio, software, news]
---

New tab
-------

There were 3 types of objects: measurements, actions and overseers. Now I have
added **addons**!

At this moment you can see what your addons are doing by getting table like data.


Api response
------------

This is sample response of `plant_monitor` addon:

```javascript
{  
   "status":0,
   "object":{  
      "array":[  
         {  
            "msWateredAgo":515720388,
            "preWater":80.078125,
            "postWater":88.671875,
            "drySpeed":0.000719,
            "waterNeededIn":1215002270,
            "waterAtValue":50.000000,
            "minValue":44.140625,
            "minValueAgo":1575903852,
            "maxValue":89.648438,
            "maxValueAgo":515705034
         }
      ],
      "name":"plant_monitor",
      "keys":[  
         {  
            "key":"msWateredAgo",
            "type":"interval"
         },
         {  
            "key":"preWater",
            "type":"float",
            "unit":"%"
         }
      ]
   }
}
```

* `object` - response of command
  * `array` - array of hashes: `column key` -> `value`
  * `name` - name of addon
  * `keys` - array of useful information how to render this data


Sample image
------------

Plant monitor

![Plant monitor](/images/web_addon_plant_stats.png)

Wind turbine stats

![Wind turbine stats](/images/web_addon_wind_hourly_stats.png)


End
---

More features coming soon. Feel free to [ask for them](https://github.com/HomeIO/homeio_backend/issues/new).
