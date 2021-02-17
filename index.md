---
layout: home
---

I'm a Machine Learning Engineer at [iRobot](https://www.irobot.com/). Previously, I was a postdoctoral researcher at [IST Austria](https://ist.ac.at/en/) and a PhD student at [UBC](http://www.math.ubc.ca/).

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
