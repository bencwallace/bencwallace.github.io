---
layout: home
---

I'm a software engineer focused on applications of machine learning.
I mostly use this site to collect some projects I've worked on in my spare time (below).
You can also find some of my academic work [here](academic.md).

***

## projects

{% for repo in site.data.repos %}
**[{{ repo.name }}](https://github.com/bencwallace/{{ repo.github }})**  
{{ repo.summary }}
{% endfor %}
