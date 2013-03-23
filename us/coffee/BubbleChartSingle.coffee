class @BubbleChart
  constructor: (id, data, color) ->
    @id = "##{id}"
    @data = data
    @width = 940
    @height = 700

    @colorScheme = if !color? then "RdGy" else color

    @percent_formatter = d3.format(",.2f")
    @fixed_formatter = d3.format(",d")

    # locations the nodes will move towards
    # depending on which view is currently being
    # used
    @center = {x: @width / 2, y: @height / 2}

    @xDelta = @width
    @yDelta = @height

    # used when setting up force and
    # moving around nodes
    @layout_gravity = -0.01
    @damper = 0.12
    @charge = (d) -> -Math.pow(d.radius, 2) / 7.5
    @friction = 0.92

    # these will be set in create_nodes and create_vis
    @vis = null
    @force = null

    # use Cynthia Brewer color brewer classes
    @color_class = (n) => "q1-6"

    @max_range = 65
    @max_amount = d3.max(@data, (d) -> d.value)
    @scale()

  scale: () =>
    @radius_scale = d3.scale.pow().exponent(0.5).domain([0, @max_amount]).range([2, @max_range])

  # create svg at #vis and then
  # create circle representation for each node
  create_vis: () =>

    $(@id).children().remove()
    $(@id).css("width", "#{@width}px")
    $(@id).css("height", "#{@height}px")

    @vis = d3.select(@id)
    .append("svg")
      .attr("width", @width)
      .attr("height", @height)
      .attr("id", "svg_vis")
      .attr("class",@colorScheme)

  get_bubble: (cell, data) =>
    cell.selectAll("circle")
    .data(data)

  create_circles: (cell, data) =>
    that = this

    @get_bubble(cell, data)
    .enter()
    .append("circle")
    .attr("r", 0)
    .attr("class", (d) => @color_class(d.group))
    .attr("stroke-width", 2)
    .attr("stroke", (d) -> d3.rgb($(this).css("fill")).darker())
    .attr("id", (d) -> "#{d.id}")
    .on("mouseover", (d,i) -> that.show_details(d,i,this))
    .on("mouseout", (d,i) -> that.hide_details(d,i,this))

  update_circles: (cell, data) =>
    @get_bubble(cell, data)
    .attr("stroke", (d) -> d3.rgb($(this).css("fill")).darker())

  force_layout: (circles, data, size, move) =>
    if @force?
        @force.stop()

    @force = d3.layout.force()
      .nodes(data)
      .size(size)

    @force.gravity(@layout_gravity)
    .charge(@charge)
    .friction(@friction)
    .on "tick", (e) => @on_tick(move, e, circles)

  plot: (cell, data) =>
    circles = @create_circles(cell, data)
    # Fancy transition to make bubbles appear, ending with the correct radius
    circles.transition().duration(2000).attr("r", (d) -> d.radius)

    force = @force_layout(circles, data, [@xDelta, @yDelta], @move_towards_center)
    force.start()

  # Sets up force layout to display
  # all nodes in one circle.
  display: () =>
    @plot(@vis, @data)

  # Moves all circles towards the @center
  # of the visualization
  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * @damper * alpha
      d.y = d.y + (@center.y - d.y) * @damper * alpha

  on_tick: (move, e, circles) =>
    circles.each(move(e.alpha))
    .attr("cx", (d) -> d.x)
    .attr("cy", (d) -> d.y)

  load_overlay: (data, i, element) => false

  set_color_scheme: (color) =>
    @colorScheme = color
    @vis = @vis.attr("class", color)

  show_details: (data, i, element) =>
    undefined

  hide_details: (data, i, element) =>
    undefined