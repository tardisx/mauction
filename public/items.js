var item_template;
var item_detail_template;

function render_item_collection(div, items) {
    var html;
    $.each(items, function(idx, an_item) { html += render_item_html(an_item); });
    $('#'+div).html(html);
}

function render_item_html(item) {
    if (! item_template) {
        $.ajax('/partial/item.html', { async: false })
            .success(function(template) {
                console.log('suucccess', template);
                item_template = template;
            });
    }

    var new_item;

    new_item = item_template
        .replace('DESCR', item.description)
        .replace('NAME', item.name)
        .replace('LINK_URL', '/item/' + item.id)
        .replace('LINK_TEXT', item.id);

    if (item.current_price) {
        new_item = new_item.replace('HIGHBID', item.current_price);
    }

    else {
        new_item = new_item.replace('HIGHBID', 'no bids yet');
    }

    return new_item;
}

function render_item_detail_html(item) {
    if (! item_detail_template) {
        $.ajax('/partial/item_detail.html', { async: false })
            .success(function(template) {
                console.log('suucccess', template);
                item_detail_template = template;
            });
    }

    var new_item;

    new_item = item_detail_template
        .replace('DESCR', item.description)
        .replace('NAME', item.name)
        .replace('LINK_URL', '/item/' + item.id)
        .replace('LINK_TEXT' , item.id);

    if (item.current_price) {
        new_item = new_item.replace('HIGHBID', item.current_price);
    }

    else {
        new_item = new_item.replace('HIGHBID', 'no bids yet');
    }

    return new_item;
}


