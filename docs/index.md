---
layout: home
list_title: "Posts"
---

I'm a software engineer focused on applications of machine learning.
I mostly use this site to collect some projects I've worked on and thoughts
I've written down in my spare time (below).
You can also find some of my academic work [here](academic.md).

***

Projects
{: .post-list-heading}

{% for repo in site.data.repos %}
## [{{ repo.name }}](https://github.com/bencwallace/{{ repo.github }})
{{ repo.summary }}
{% endfor %}
