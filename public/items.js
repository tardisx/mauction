var item_template;

function render_items(div, items) {
    console.log('rendering some items into ' + div);
    console.log(items);
    var html;
    $.each(items, function(idx, an_item) { html += render_item(an_item); });
    $('#'+div).html(html);
}

function render_item(item) {
    if (! item_template) {
        $.ajax('/partial/item.html', { async: false })
            .success(function(template) {
                console.log('suucccess', template);
                item_template = template;
            });
    }
    console.log('rendering for ', item);

    var new_item;

    new_item = item_template
        .replace('DESCR', item.description)
        .replace('NAME', item.name);

    if (item.current_winner_for_item) {
        new_item = new_item.replace('HIGHBID', item.current_winner_for_item);
    }

    else {
        new_item = new_item.replace('HIGHBID', 'no bids yet');
    }

    return new_item;
}
