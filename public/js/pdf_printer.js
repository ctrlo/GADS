/**
 * Get end of item row Y coordinate. This includes padding to next row.
 * @returns {int}
 */
function getCurrentRowTopY() {
    return currentHeight + padding + borderSize;
}

/**
 * Get the height of the row, This includes padding to next row.
 * @param {boolean} includeNextRowPadding
 * @returns {int}
 */
function getRowYOffset(includeNextRowPadding = true) {
    return lineHeight + (padding * 2) + (borderSize * 2) + (includeNextRowPadding ? padding * 2 : 0);
}

/**
 * Get end of item row Y coordinate. This includes padding to next row.
 * @returns {int}
 */
function getCurrentRowBottomY() {
    return getCurrentRowTopY() + getRowYOffset();
}

/**
 * Gets the leading zero page number that is used in the page identifier.
 * @param {number} pageNumber
 * @returns {string}
 */
function getLeadingZeroNumber(pageNumber) {
    return parseInt(pageNumber, 10).toString().padStart(3, "0");
}

/**
 * Calculates the width of a text on the canvas without placing the text.
 * @param {text} string
 * @return {number}
 */
function getTextWidthOnCanvas(string) {
    context.font = fontSize + "px " + font;
    return context.measureText(string).width;
}

/**
 * Sets the context variable to the requested page canvas.
 * @returns void
 */
function setDrawContext(pageId) {
    canvas = document.getElementById(pageId);

    if (!canvas) {
        console.error("unable to determine canvas. setDrawContext(" + pageId + ") failed.");
        return;
    }

    context = canvas.getContext("2d");
}

/**
 * Draws the page background.
 * @returns void
 */
function drawBackground() {
    context.fillStyle = backgroundColor;
    context.fillRect(0, 0, context.canvas.width, context.canvas.height);
}

/**
 * Draws all objects passed in an array.
 * @returns void
 */
function drawObjects(objects) {
    $.each(objects, function () {
        this.draw();
    });
}

/**
 * Draws the vertical major and minor lines on the topXAxisBar, bottomXAxisBar and the groups.
 * @param {number} startMajorY vertical Y coordinate to start drawing the major bars at
 * @param {number} startMinorY vertical Y coordinate to start drawing the minor bars at
 * @param {number} endMajorY vertical Y coordinate to end drawing the major bars at
 * @param {number} endMinorY vertical Y coordinate to end drawing the minor bars at
 * @param {boolean} drawLabels determines whether major and minor labels will be drawn. This is needed when rendering
 *                             the top and bottom X axis bars. These are the years/months/days/hours above and below
 *                             the timeline.
 * @returns {number} endX the end coordinate where the rendering stops. This is used for drawing the right border of
 *                        the timeline components.
 */
function drawXAxisBarsAndSeparators(startMajorY, startMinorY, endMajorY, endMinorY, drawLabels = false) {
    const bar = pageData.xAxis;
    const startX = tableYAxisBarWidth;

    if(! bar.major || bar.major.length === 0) {
        return pageWidth;
    }

    let objects = [];
    let currentX = bar.x * pageScaleFactor + startX;
    let currentMajorX = currentX;

    $.each(bar.major, function() {
        const major = this;

        if(this.minor && this.minor.length > 0) {
            $.each(this.minor, function(minorKey, minorValue) {
                // draw major and minor vertical separator lines
                if(currentX > startX) {
                    const lineStartY = minorKey > 0 ? startMinorY : startMajorY;
                    const lineEndY   = minorKey > 0 ? endMinorY : endMajorY;
                    const lineColor  = minorKey > 0 ? xAxisMinorColor : foregroundColor;

                    // minor separator
                    objects.push(new Line(currentX, lineStartY, currentX, lineEndY, lineColor, borderSize));
                }

                // draw minor labels
                if(drawLabels) {
                    const minorTextStartX = currentX + xAxisPadding;
                    const minorTextStartY = startMinorY + xAxisPadding + fontSize;
                    const minorTextMaxWidth = this.width * pageScaleFactor - (xAxisPadding * 2);

                    objects.push(new Text(minorTextStartX, minorTextStartY, this.text, minorTextMaxWidth, xAxisTextColor));
                }

                currentX += this.width * pageScaleFactor;
            });
        }

        // draw major labels
        if(drawLabels) {
            const isBottomBar = startMinorY === startMajorY;
            const majorTextStartX = currentMajorX > startX ? currentMajorX + xAxisPadding : tableYAxisBarWidth + xAxisPadding;
            const majorTextStartY = (isBottomBar ? endMinorY : startMajorY) + xAxisPadding + fontSize;
            const majorTextMaxWidth = currentX - currentMajorX - (xAxisPadding * 2);
            objects.push(new Text(majorTextStartX, majorTextStartY, major.text, majorTextMaxWidth, xAxisTextColor));

            if(showYAxisBar) {
                // hide overflow labels on xAxisTop and xAxisBottom bar on the left side.
                // the right side is handled by the canvas overflow.
                const startRectangleY = isBottomBar ? startMajorY + 1 : 0;
                objects.push(new Rectangle(0, startRectangleY, tableYAxisBarWidth, tableXAxisBarHeight));
            }
        }

        currentMajorX = currentX;
    });

    drawObjects(objects);

    return Math.round(currentX > pageWidth ? pageWidth : currentX);
}

/**
 * This function parses rows in a group recursively to detect possible colliding rows and move the colliding
 * Items to a new row.
 * @param {object} group
 * @return {{label, rows: *[]}}
 */
function preventPageGroupRowCollisions(group) {
    let cleanGroup = {
        label: group.label,
        rows: []
    };

    $.each(group.rows, function(index, row) {
        let rowItems     = [];
        let cleanRow     = { items: [] };
        let collisionRow = { items: [] };

        $.each(row.items, function() {
            const item = new Item(this.x, 0, this.width);

            // sort items based on whether they collide with other items on the current row
            if(! item.collidesX(rowItems)) {
                cleanRow.items.push(this);
                rowItems.push(item);
            } else {
                collisionRow.items.push(this);
            }
        });


        if(cleanRow.items.length) {
            cleanGroup.rows.push(cleanRow);
        }

        // if there where collisions, move the colliding items to a new row, and check for collisions on the new row.
        // this is done recursively until there are no more collisions.
        if(collisionRow.items.length) {
            const cleanedCollisions = preventPageGroupRowCollisions({
                label: group.label,
                rows: [collisionRow]
            });

            $.each(cleanedCollisions.rows, function() {
                cleanGroup.rows.push(this);
            });
        }
    });

    return cleanGroup;
}

/**
 * Draws a row of items on a page (HTML canvas).
 * @param {number} page
 * @param {object} row
 * @param {number} topY
 * @param {number} endX
 */
function drawPageGroupRow(page, row, topY, endX) {
    const pageId = getPageId(page);

    setDrawContext(pageId);

    let objects = [];

    $.each(row.items, function() {
        objects.push(new Item(this.x, topY, this.width, this.text, endX, this.textColor, this.backgroundColor));
    });

    drawObjects(objects);
}

/**
 * Draws group borders, label and background separators on one or more pages (HTML canvasses).
 * @param {object} group
 * @param {number} startY
 * @param {boolean} groupStartsOnPage
 * @param {boolean} groupFinishesOnPage
 * @return {number} endX
 */
function drawGroupData(group, startY, groupStartsOnPage, groupFinishesOnPage) {
    startY = startY % pageHeight;
    let endY = currentHeight % pageHeight;
    let objects = [];

    // group left border
    objects.push(new Line(0, startY, 0, endY));

    // group column separation border
    if(showYAxisBar) {
        objects.push(new Line(tableYAxisBarWidth, startY, tableYAxisBarWidth, endY));
    }

    // group label
    if(showYAxisBar && groupStartsOnPage) {
        const textX        = padding + borderSize;
        const textY        = startY + lineHeight + borderSize;
        const textMaxWidth = tableYAxisBarWidth - padding * 2 - borderSize * 2;
        const textLabel    = group.label
                                  .replace('&amp;lt;', '<')
                                  .replace('&lt;', '<')
                                  .replace('&amp;gt;', '>')
                                  .replace('&gt;', '>')
                                  .replace('&amp;', '&');

        objects.push(new Text(textX, textY, textLabel, textMaxWidth, false, false,true));
    }

    // group major and minor columns
    const endX = drawXAxisBarsAndSeparators(startY, startY, endY, endY, false);

    // group right border
    objects.push(new Line(endX, startY, endX, endY));

    // group border bottom, end of group
    if(groupFinishesOnPage) {
        objects.push(new Line(0, endY, endX, endY));
    }

    drawObjects(objects);

    return endX;
}

/**
 * This functions draws the page group on one or more pages (HTML canvasses).
 * @param {object} group
 * @returns void
 */
function drawPageGroup(group) {
    let startY = currentHeight;
    let groupStartsOnPage   = true;
    let groupFinishesOnPage = true;
    let rowsCache = [];

    // make room for the group label, if the group has no rows.
    if(! group.rows || group.rows.length === 0) {
        currentHeight += getRowYOffset();
    }
    else {
        group = preventPageGroupRowCollisions(group);

        $.each(group.rows, function() {
            // check if the row would fall on the next page
            if(getCurrentRowTopY() % pageHeight > getCurrentRowBottomY() % pageHeight) {
                currentHeight += pageHeight - getCurrentRowTopY() + padding;
                groupFinishesOnPage = false;
                drawGroupData(group, startY, groupStartsOnPage, groupFinishesOnPage);
                createPage();
                groupStartsOnPage = false;
                startY = 0;
            }

            // rows are cached, so that they are drawn on top of the background lines, after the height of the group,
            // and the pages that they fall on have been determined through this loop.
            const topY = getCurrentRowTopY() % pageHeight;
            rowsCache.push({page: pageNumber, row: this, topY: topY});
            currentHeight += getRowYOffset();
        });
    }

    groupFinishesOnPage = true;
    // draw group borders, label and background separators
    const endX = drawGroupData(group, startY, groupStartsOnPage, groupFinishesOnPage);

    // draw rows in group
    if([] !== rowsCache) {
        $.each(rowsCache, function(index, row) {
            drawPageGroupRow(row.page, row.row, row.topY, endX);

            // current time indicator in red
            if(currentTimeX <= endX) {
                // first and last item in group must overwrite the default padding
                const startTextY = index === 0 ? row.topY - padding : row.topY;
                const endTextY = index === rowsCache.length -1
                            ? row.topY + getRowYOffset(false) + padding
                            : row.topY + getRowYOffset();

                drawObjects([new Line(currentTimeX, startTextY, currentTimeX, endTextY, currentTimeColor, currentTimeThickness)]);
            }
        });
    }
}

/**
 * Draws the top bar with labels along the X-Axis of the timeline.
 * @returns void
 */
function drawXAxisTopBar() {
    const bar = pageData.xAxis;
    const startX = tableYAxisBarWidth;
    const topY = currentHeight;
    const minorTopY = topY + lineHeight + (xAxisPadding * 2);
    const bottomY = topY + bar.height;
    let objects = [];

    // left border
    objects.push(new Line(startX, topY, startX, bottomY));

    //
    const endX = drawXAxisBarsAndSeparators(topY, minorTopY, bottomY, bottomY, true);

    // top border
    objects.push(new Line(startX, topY, endX, topY));

    // bottom border
    objects.push(new Line(0, bottomY, endX, bottomY));

    // right border
    objects.push(new Line(endX, topY, endX, bottomY));

    // current time indicator in red
    if(currentTimeX <= endX) {
        objects.push(new Line(currentTimeX, topY, currentTimeX, bottomY, currentTimeColor, currentTimeThickness));
    }

    drawObjects(objects);

    currentHeight += bar.height;
}

/**
 * Draws the bottom bar with labels along the X-Axis of the timeline.
 * @returns void
 */
function drawXAxisBottomBar() {
    const bar = pageData.xAxis;
    const startX = tableYAxisBarWidth;
    let topY = currentHeight % pageHeight;
    let bottomY = topY + bar.height;
    let minorBottomY = topY + lineHeight + (xAxisPadding * 2);
    let objects = [];

    // check if the X axis bottom bar would fall on the next page, render and move the bar to the top of the new page
    if(topY % pageHeight > bottomY % pageHeight) {
        createPage();
        topY = 0;
        bottomY = bar.height;
        minorBottomY = lineHeight + (xAxisPadding * 2);
    }

    // left border
    objects.push(new Line(startX, topY, startX, bottomY));

    const endX = drawXAxisBarsAndSeparators(topY, topY, bottomY, minorBottomY, true);

    // bottom border
    objects.push(new Line(startX, bottomY, endX, bottomY));

    // right border
    objects.push(new Line(endX, topY, endX, bottomY));

    // current time indicator in red
    if(currentTimeX <= endX) {
        objects.push(new Line(currentTimeX, topY, currentTimeX, bottomY, currentTimeColor, currentTimeThickness));
    }

    drawObjects(objects);

    currentHeight += bar.height;
}

/**
 * This function determines the page ID for a canvas based on its page number
 * @param page int
 * @returns string
 */
function getPageId(page) {
    return pagePrefix + getLeadingZeroNumber(page);
}

/**
 * Creates a new page with a canvas to be printed as a PDF
 * @returns void
 */
function createPage() {
    const previousPageNumber = pageNumber;
    pageNumber++;
    const pageId = getPageId(pageNumber);
    const pageOffset = previousPageNumber * pageHeight;
    const pages = $("canvas.page");
    const pageCanvasHtml =
              "<canvas " +
              "id=\"" + pageId + "\" " +
              "class=\"page\" " +
              "style=\"top: " + pageOffset + "px;\" " +
              "width=\"" + pageWidth + "\" " +
              "height=\"" + pageHeight + "\"" +
              "style=\"width: " + pageWidth + "px;\"" +
              "></canvas>";

    if (pages.length) {
        pages.last().after(pageCanvasHtml);
    } else {
        $("body").prepend(pageCanvasHtml);
    }

    // mark the current page for drawing.
    setDrawContext(pageId);
    drawBackground();
}

/**
 * Line object that draws a single line on the current draw context (a canvas)
 */
function Line(startX, startY, toX, toY, color = false, thickness = 1) {
    this.startX = startX;
    this.startY = startY;
    this.toX = toX;
    this.toY = toY;
    this.color = color ? color : foregroundColor;
    this.thickness = thickness;

    this.draw = function () {
        context.beginPath();
        context.moveTo(this.startX, this.startY);
        context.lineTo(this.toX, this.toY);

        context.fillStyle = this.color;
        context.strokeStyle = this.color;
        context.lineWidth = this.thickness;

        context.stroke();
    }
}

/**
 * Text object that draws a text on the current draw context (a canvas)
 */
function Text(x, y, text, maxWidth = false, textColor = false, shadowColor = false, bold = false) {
    this.x = x;
    this.y = y;
    this.maxWidth = maxWidth;
    this.text = text;
    this.color = textColor ? textColor : foregroundColor;
    this.shadowColor = shadowColor;

    this.draw = function () {
        context.font = (bold ? 'bold ' : '') + fontSize + "px " + font;

        if(this.shadowColor) {
            context.shadowColor = this.shadowColor;
            context.shadowBlur = 1;
            context.lineWidth = 1;

            context.strokeText(this.text,this.x, this.y, this.maxWidth);

            context.shadowBlur = 0;
        }

        context.fillStyle = this.color;
        if(maxWidth !== false) {
            context.fillText(this.text, this.x, this.y, this.maxWidth);
        }
        else {
            context.fillText(this.text, this.x, this.y);
        }
    }
}

/**
 * Rectangle object that draws a solid rectangle on the current draw context (a canvas)
 */
function Rectangle(x, y, width, height, color = false) {
    this.x = x;
    this.y = y;
    this.w = width;
    this.h = height;
    this.color = color ? color : backgroundColor;

    this.draw = function () {
        context.fillStyle = this.color;
        context.fillRect(this.x, this.y, this.w, this.h);
    }
}

/**
 * Item object that draws a bar with text and border (a representation of a vis-item line) on the current draw
 * context (a canvas).
 */
function Item(x, y, width, text, endX, textColor = false, customBackgroundColor = false) {
    // apply pageScaleFactor to scanned properties only, as properties based on
    // page settings have already been scaled
    this.x = x * pageScaleFactor;
    this.y = y;
    this.w = width * pageScaleFactor;
    this.h = lineHeight + (padding * 2) + (borderSize * 2);
    this.text = text;
    this.endX = endX;
    this.textColor = textColor ? textColor : foregroundColor;
    this.backgroundColor = customBackgroundColor ? customBackgroundColor : backgroundColor;

    this.draw = function () {
        // reduce width and x position when part of the item falls under the tableYAxisBarWidth or
        // off the left edge of the page. this corrects the bar + text start position and the total width
        if(this.x < tableYAxisBarWidth) {
            // a node can fall completely off the left border due to scrolling, and not be unloaded by VisJS,
            // so it must be skipped
            if(this.x + this.w < 0) {
                return;
            }

            this.w = this.w + this.x;   // reduce width by the x position
            this.x = tableYAxisBarWidth;// start where the Y axis bar starts
        }
        // for items that are displayed fully, correct the X position on the canvas with the
        // tableYAxisBarWidth to place the item after the bar
        else {
            this.x = this.x + tableYAxisBarWidth;
        }

        // reduce width of items that fall off the page on the right border
        if(this.x + this.w > endX) {
            this.w = endX - this.x;
        }

        context.strokeStyle = foregroundColor;
        context.lineWidth = borderSize;
        context.fillStyle = this.backgroundColor;
        context.fillRect(this.x, this.y, this.w, this.h);
        context.strokeRect(this.x, this.y, this.w, this.h);

        const textX = this.x + padding + borderSize;
        const textY = this.y + padding + fontSize + borderSize;
        const textObj = new Text(textX, textY, this.text, false, this.textColor, this.backgroundColor)

        textObj.draw();

        // when an item is drawn over the right page border, it interrupts the border.
        // this draws the border inside the item so that the border continues visually.
        if(this.x + this.w >= this.endX) {
            const lineObj = new Line(this.endX, this.y, this.endX, this.y + this.h);

            lineObj.draw();
        }
    }

    /**
     * Detects whether the current item collides with a previously drawn item in a row on the X axis
     * @param items
     * @returns {boolean}
     */
    this.collidesX = function(items) {
        const newItemOnRow = this;
        let collides       = false;

        $.each(items, function() {
            const existingItemOnRow  = this;
            const existingItemStartX = existingItemOnRow.x
            const existingItemEndX   = existingItemStartX + Math.max(existingItemOnRow.w, getTextWidthOnCanvas(existingItemOnRow.text) + padding * 2);
            const newItemStartX      = newItemOnRow.x;
            const newItemEndX        = newItemStartX + Math.max(newItemOnRow.w, getTextWidthOnCanvas(newItemOnRow.text) + padding * 2);

            // collision scenarios
            if(
                // new item starts before the existing item, but overlaps with the existing item due to its width
                (newItemStartX < existingItemStartX && newItemEndX >= existingItemStartX ) ||
                // new item starts inside of the existing item
                (newItemStartX >= existingItemStartX && newItemStartX <= existingItemEndX)
            ) {
                collides = true;
                return false;
            }
        });

        return collides;
    }
}

/**
 * Initialize the timeline rendering.
 */
function drawTimelinePdf() {
    const groups = pageData.groups;

    createPage();
    drawXAxisTopBar();

    $.each(groups, function () {
        drawPageGroup(this);
    });

    drawXAxisBottomBar();
}
