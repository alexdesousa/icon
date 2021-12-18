ExUnit.start()
:ok = Application.put_env(:icon, :url_builder, Icon.URLBuilder)
{:ok, _} = Icon.URLBuilder.start_link()
Icon.Config.preload()
