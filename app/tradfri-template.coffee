$(document).on "templateinit", (event) ->


##############################################################
# TradfriDimmerItem - Old Version
##############################################################
  class TradfriDimmerItem extends pimatic.SwitchItem
    constructor: (templData, @device) ->
      super(templData, @device)
      @sliderId = "switch-#{templData.deviceId}"
      dimAttribute = @getAttribute('dimlevel')
      unless dimAttribute?
        throw new Error("A dimmer device needs an dimlevel attribute!")
      dimlevel = dimAttribute.value
      @sliderValue = ko.observable(if dimlevel()? then dimlevel() else 0)
      dimAttribute.value.subscribe( (newDimlevel) =>
        @sliderValue(newDimlevel)
        pimatic.try => @sliderEle.slider('refresh')
      )

    onSliderStop: ->
      @sliderEle.slider('disable')
      pimatic.loading(
        "dimming-#{@sliderId}", "show", text: __("dimming to %s%", @sliderValue())
      )
      @device.rest.changeDimlevelTo( {dimlevel: @sliderValue()}, global: no).done(ajaxShowToast)
      .fail( =>
        pimatic.try => @sliderEle.val(@getAttribute('dimlevel').value()).slider('refresh')
      ).always( =>
        pimatic.loading "dimming-#{@sliderId}", "hide"
        # element could be not existing anymore
        pimatic.try( => @sliderEle.slider('enable'))
      ).fail(ajaxAlertFail)

    afterRender: (elements) ->
      super(elements)
      @sliderEle = $(elements).find('input')
      @sliderEle.slider()
      $(elements).find('.ui-slider').addClass('no-carousel-slide')


##############################################################
# TradfriDimmerSliderItem - Only Dimmer
##############################################################
  class TradfriDimmerSliderItem extends pimatic.SwitchItem

    constructor: (templData, @device) ->
      super(templData, @device)
      #DIMMER
      @dsliderId = "dimmer-#{templData.deviceId}"
      dimAttribute = @getAttribute('dimlevel')
      unless dimAttribute?
        throw new Error("A dimmer device needs an dimlevel attribute!")
      dimlevel = dimAttribute.value
      @dsliderValue = ko.observable(if dimlevel()? then dimlevel() else 0)
      dimAttribute.value.subscribe( (newDimlevel) =>
        @dsliderValue(newDimlevel)
        pimatic.try => @dsliderEle.slider('refresh')
      )

    onSliderStop: ->
      console.log("1")
      @dsliderEle.slider('disable')
      pimatic.loading(
        "new dimming value", "show", text: __("dimming to %s%", @dsliderValue())
      )
      @device.rest.changeDimlevelTo( {dimlevel: @dsliderValue()}, global: no).done(ajaxShowToast)
      .fail( =>
        pimatic.try => @dsliderEle.val(@getAttribute('dimlevel').value()).slider('refresh')
      ).always( =>
        pimatic.loading "dimmer-#{@dsliderId}", "hide"
        # element could be not existing anymore
        pimatic.try( => @dsliderEle.slider('enable'))
      ).fail(ajaxAlertFail)

    afterRender: (elements) ->
      super(elements)
      @dsliderEle = $(elements).find('.ddimmer')
      @dsliderEle.slider()
      $(elements).find('.ui-slider').addClass('no-carousel-slide')

      $('#index').on("slidestop", " #item-lists .ddimmer", (event) ->
          dimmerDevice = ko.dataFor(this)
          dimmerDevice.onSliderStop()
          return
      )

##############################################################
# TradfriDimmerTempSliderItem
##############################################################
  class TradfriDimmerTempSliderItem extends TradfriDimmerSliderItem
    constructor: (templData, @device) ->
      super(templData, @device)
      #COLOR
      @csliderId = "color-#{templData.deviceId}"
      colorAttribute = @getAttribute('color')
      unless colorAttribute?
        throw new Error("A dimmer device needs an color attribute!")
      color = colorAttribute.value
      @csliderValue = ko.observable(if color()? then color() else 0)
      colorAttribute.value.subscribe( (newColor) =>
        @csliderValue(newColor)
        pimatic.try => @csliderEle.slider('refresh')
      )

    onSliderStop2: ->
      console.log("2")
      @csliderEle.slider('disable')
      pimatic.loading(
        "new color value", "show", text: __("set to %s%", @csliderValue())
      )
      @device.rest.setColor( {colorCode: @csliderValue()}, global: no).done(ajaxShowToast)
      .fail( =>
        pimatic.try => @csliderEle.val(@getAttribute('color').value()).slider('refresh')
      ).always( =>
        pimatic.loading "color-#{@csliderId}", "hide"
        # element could be not existing anymore
        pimatic.try( => @csliderEle.slider('enable'))
      ).fail(ajaxAlertFail)

    afterRender: (elements) ->
      @csliderEle = $(elements).find('.cdimmer')
      @csliderEle.slider()
      super(elements)

      $('#index').on("slidestop", " #item-lists .cdimmer", (event) ->
          dimmerDevice = ko.dataFor(this)
          dimmerDevice.onSliderStop2()
          return
      )

##############################################################
# TradfriDimmerTempSliderItem
##############################################################
  class TradfriDimmerTempButtonItem extends TradfriDimmerSliderItem
    constructor: (templData, @device) ->
      super(templData, @device)
      @warmId = "wbutton-#{templData.deviceId}"
      @normalId = "nbutton-#{templData.deviceId}"
      @coldId = "cbutton-#{templData.deviceId}"

    afterRender: (elements) ->
      super(elements)
      @warmButton = $(elements).find('[name=warmButton]')

    setWarm: -> @setColor "warm"

    setCold: -> @setColor "cold"

    setNormal: -> @setColor "normal"

    setColor: (temp) ->
        @device.rest.setColor({colorCode: temp}, global: no)
          .done(ajaxShowToast)
          .fail(ajaxAlertFail)

  pimatic.templateClasses['tradfridimmer'] = TradfriDimmerItem
  pimatic.templateClasses['tradfridimmer-dimmer'] = TradfriDimmerSliderItem
  pimatic.templateClasses['tradfridimmer-temp-slide'] = TradfriDimmerTempSliderItem
  pimatic.templateClasses['tradfridimmer-temp-buttons'] = TradfriDimmerTempButtonItem
