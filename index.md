---
layout: home
---

I'm a Machine Learning Engineer at [iRobot](https://www.irobot.com/). Before that, I did mathematical research at [IST Austria](https://ist.ac.at/en/) and [UBC](http://www.math.ubc.ca/).

***

## repos

{% for repo in site.data.repos %}
**[{{ repo.name }}](https://github.com/bencwallace/{{ repo.github }})**  
{{ repo.summary }}
{% endfor %}

***

## pubs

{% for pub in site.data.pubs %}
**{{ pub.title }}**  
Co-authors: {{ pub.coauthors | join: ", " }}  
| {% for link in pub.links %} [{{ link.name }}]({{ link.dest }}) |{% endfor %}
{% endfor %}

***

## theses

{% for thesis in site.data.theses %}
**{{ thesis.title }}**  
[{{ thesis.link.name }}]({{ thesis.link.dest }})
{% endfor %}
