
module.exports = (env) ->

  class Color

    hue2rgb = (p, q, t) =>
      if t < 0
        t += 1
      if (t > 1)
        t -= 1
      if (t < 1/6)
        return p + (q - p) * 6 * t
      if (t < 1/2)
        return q
      if (t < 2/3)
        return p + (q - p) * (2/3 - t) * 6
      return p

# Source https://stackoverflow.com/questions/27653757/how-to-use-hsl-to-rgb-conversion-function
    @hslToRgb =  (h, s, l) ->
      h=h/360
      if (s == 0)
        r = g = b = l
      else
        q = if l < 0.5 then l * (1 + s) else l + s - l * s
        p = 2 * l - q
        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)

      return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];

    check = (val) =>
      val = Math.max(Math.min(val, 255), 0) / 255.0
      if val <= 0.04045
        return val / 12.92
      else
        return ((val + 0.055) / 1.055) ** 2.4

# Source http://stackoverflow.com/a/36061908
    @rgb_to_xyY = (r, g, b) ->
      r = check(r)
      g = check(g)
      b = check(b)
      X = 0.76103282*r + 0.29537849*g + 0.04208869*b
      Y = 0.39240755*r + 0.59075697*g + 0.01683548*b
      Z = 0.03567341*r + 0.0984595*g + 0.22166709*b
      total = X + Y + Z
      if ( total == 0 )
        return  [ 23000 , 23000 ]
      else
        return [ parseInt(X*65535+0.5)/total , parseInt(Y*65535+0.5)/total, parseInt(Y*65535+0.5)/total ]

    @kelvin_to_xy = (T) =>
# Sources: "Design of Advanced Color - Temperature Control System
#           for HDTV Applications" [Lee, Cho, Kim]
# and https://en.wikipedia.org/wiki/Planckian_locus#Approximation
# and http://fcam.garage.maemo.org/apiDocs/_color_8cpp_source.html
      if T <= 4000
        x = -0.2661239*(10**9)/T**3 - 0.2343589*(10**6)/T**2 + 0.8776956*(10**3)/T + 0.17991
      else if T <= 25000
        x = -3.0258469*(10**9)/T**3 + 2.1070379*(10**6)/T**2 + 0.2226347*(10**3)/T + 0.24039

      if T <= 2222
        y = -1.1063814*x**3 - 1.3481102*x**2 + 2.18555832*x - 0.20219683
      else if T <= 4000
        y = -0.9549476*x**3 - 1.37418593*x**2 + 2.09137015*x - 0.16748867
      else if T <= 25000
        y = 3.081758*x**3 - 5.8733867*x**2 + 3.75112997*x - 0.37001483

      xr = x*65535+0.5
      yr = y*65535+0.5

      [
        parseInt(xr)
        parseInt(yr)
      ]

 # Source: https://en.wikipedia.org/wiki/Color_temperature#Approximation
    @xyY_to_kelvin = (x, y) =>
      n = (x/65535-0.3320) / (y/65535-0.1858)
      kelvin = parseInt((-449*n**3 + 3525*n**2 - 6823.3*n + 5520.33) + 0.5)
