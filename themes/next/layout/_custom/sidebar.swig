{% if site.categories.length > 0 %}
<div>
    <ul>
    {% for cat in site.categories %}
        {% if cat.posts.length > 0 %}
            <li><a href="{{ config.root }}{{ cat.path }}" title="{{ cat.name }}">{{ cat.name }}<sup>{{ cat.posts.length }}</sup></a></li>
        {% endif %}
    {% endfor %}
    </ul>
</div>
{% endif %}