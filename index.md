---
layout: home
---

My name is Ben Wallace. I'm a Machine Learning Engineer at [iRobot](https://www.irobot.com/). Before that, I did research in math (probability / statistical physics) at [IST Austria](https://ist.ac.at/en/) and [UBC](http://www.math.ubc.ca/). Below are the results of some of my personal and professional projects.

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
