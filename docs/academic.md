Before getting into machine learning, I did research on probability theory and statistical physics.
Below are some of my publications.

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
