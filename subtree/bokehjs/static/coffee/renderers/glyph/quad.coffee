
properties = require('../properties')
glyph_properties = properties.glyph_properties
line_properties = properties.line_properties
fill_properties = properties.fill_properties

glyph = require('./glyph')
Glyph = glyph.Glyph
GlyphView = glyph.GlyphView


class QuadView extends GlyphView

  initialize: (options) ->
    glyphspec = @mget('glyphspec')
    @glyph_props = new glyph_properties(
      @,
      glyphspec,
      ['right', 'left', 'bottom', 'top'],
      [
        new fill_properties(@, glyphspec),
        new line_properties(@, glyphspec)
      ]
    )

    @do_fill   = @glyph_props.fill_properties.do_fill
    @do_stroke = @glyph_props.line_properties.do_stroke
    super(options)

  _set_data: (@data) ->
    @left = @glyph_props.v_select('left', data)
    @top  = @glyph_props.v_select('top', data)
    @right  = @glyph_props.v_select('right', data)
    @bottom = @glyph_props.v_select('bottom', data)
    @mask = new Array(data.length-1)
    for i in [0..@mask.length-1]
      @mask[i] = true

  _render: () ->
    [@sx0, @sy0] = @plot_view.map_to_screen(@left,  @glyph_props.left.units,  @top,    @glyph_props.top.units)
    [@sx1, @sy1] = @plot_view.map_to_screen(@right, @glyph_props.right.units, @bottom, @glyph_props.bottom.units)

    ow = @plot_view.view_state.get('outer_width')
    oh = @plot_view.view_state.get('outer_height')
    for i in [0..@mask.length-1]
      if (@sx0[i] < 0 and @sx1[i] < 0) or (@sx0[i] > ow and @sx1[i] > ow) or (@sy0[i] < 0 and @sy1[i] < 0) or (@sy0[i] > oh and @sy1[i] > oh)
        @mask[i] = false
      else
        @mask[i] = true

    ctx = @plot_view.ctx

    ctx.save()
    if @glyph_props.fast_path
      @_fast_path(ctx)
    else
      @_full_path(ctx)
    ctx.restore()

  _fast_path: (ctx) ->
    if @do_fill
      @glyph_props.fill_properties.set(ctx, @glyph_props)
      ctx.beginPath()
      for i in [0..@sx0.length-1]
        if isNaN(@sx0[i] + @sy0[i] + @sx1[i] + @sy1[i]) or not @mask[i]
          continue
        ctx.rect(@sx0[i], @sy0[i], @sx1[i]-@sx0[i], @sy1[i]-@sy0[i])
      ctx.fill()

    if @do_stroke
      @glyph_props.line_properties.set(ctx, @glyph_props)
      ctx.beginPath()
      for i in [0..@sx0.length-1]
        if isNaN(@sx0[i] + @sy0[i] + @sx1[i] + @sy1[i]) or not @mask[i]
          continue
        ctx.rect(@sx0[i], @sy0[i], @sx1[i]-@sx0[i], @sy1[i]-@sy0[i])
      ctx.stroke()

  _full_path: (ctx) ->
    for i in [0..@sx0.length-1]
      if isNaN(@sx0[i] + @sy0[i] + @sx1[i] + @sy1[i]) or not @mask[i]
        continue

      ctx.beginPath()
      ctx.rect(@sx0[i], @sy0[i], @sx1[i]-@sx0[i], @sy1[i]-@sy0[i])

      if @do_fill
        @glyph_props.fill_properties.set(ctx, @data[i])
        ctx.fill()

      if @do_stroke
        @glyph_props.line_properties.set(ctx, @data[i])
        ctx.stroke()


class Quad extends Glyph
  default_view: QuadView
  type: 'GlyphRenderer'


Quad::display_defaults = _.clone(Quad::display_defaults)
_.extend(Quad::display_defaults, {

  fill: 'gray'
  fill_alpha: 1.0

  line_color: 'red'
  line_width: 1
  line_alpha: 1.0
  line_join: 'miter'
  line_cap: 'butt'
  line_dash: []
  line_dash_offset: 0

})


exports.Quad = Quad
exports.QuadView = QuadView
