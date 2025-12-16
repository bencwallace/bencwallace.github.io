Before moving into machine learning, I did research on probability theory and statistical physics.
My work can be found below.

***

## publications

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
