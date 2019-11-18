defmodule Web.RecaptchaView do
  use Web, :view

  def render("_recaptcha_js.html", _assigns) do
    config = Application.get_env(:grapevine, :recaptcha)

    case config[:enabled] do
      true ->
        content_tag(:script, "",
          src: "https://www.google.com/recaptcha/api.js",
          async: true,
          defer: true
        )

      false ->
        []
    end
  end

  def render("_captcha.html", _assigns) do
    config = Application.get_env(:grapevine, :recaptcha)

    case config[:enabled] do
      true ->
        captcha(config)

      false ->
        []
    end
  end

  def captcha(config) do
    content_tag(:div, class: "form-group row") do
      content_tag(:div, class: "col-md-9 offset-md-3") do
        content_tag(:div, "", class: "g-recaptcha", data: [sitekey: config[:site_key]])
      end
    end
  end
end
