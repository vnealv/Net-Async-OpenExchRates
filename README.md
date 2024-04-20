# NAME

`Net::Async::OpenExchRates` - interact with [OpenExchangeRates API](https://openexchangerates.org/) via [IO::Async](https://metacpan.org/pod/IO%3A%3AAsync)

# SYNOPSIS

    use Future::AsyncAwait;
    use IO::Async::Loop;
    use Net::Async::OpenExchRates;

    my $loop = IO::Async::Loop->new();
    my $exch = Net::Async::OpenExchRates->new(
       app_id => 'APP_ID',
    );
    $loop->add( $exch );

    my $latest = await $exch->latest();

# DESCRIPTION

This module is a simple [IO::Async::Notifier](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier) wrapper class with a [Net::Async::HTTP](https://metacpan.org/pod/Net%3A%3AAsync%3A%3AHTTP) object constructed using [Object::Pad](https://metacpan.org/pod/Object%3A%3APad).
Made to communicate with _OpenExchangeRates API_ providing all its available endpoints as methods to be called by a program.

Acting as an active Asynchronous API package for [Open Exchange Rates](https://openexchangerates.org/)
following its [API docs](https://docs.openexchangerates.org) along with providing extra functionalities
like pre-validation, local caching and respecting API update frequency depending on your `APP_ID` subscription plan.

# CONSTRUCTOR

## new

    $exch = Net::Async::OpenExchRates->new( %args );

Returns a new `Net::Async::OpenExchRates` instance,
which is a `IO::Async::Notifier` too,
where one argument is required with others being optional, detailed as so:

- app\_id => STRING (REQUIRED)

    The only required argument to be passed.
    Can be obtained from _OpenExchangeRates_ [Account page](https://openexchangerates.org/account/app-ids).

- base\_uri => STRING

    `default: 'https://openexchangerates.org'`

    The URL to be used as the base to form API request URI.

- use\_cache => BOOL

    `default: 1`

    Toggle to enable/disable the use of [Cache::LRU](https://metacpan.org/pod/Cache%3A%3ALRU) to have the response locally available
    for repeated requests only if the API responded with `304 HTTP` code for a previously cached request.
    As _OpenExchangeRates API_ offers [Cache Control](https://docs.openexchangerates.org/reference/etags)
    utilizing ETag identifiers.
    Having this enabled is effective for saving on network bandwidth and faster responses,
    but not much on API usage quota as it will still be counted as a resource request.

- cache\_size => INT

    `default: 1024`

    The size limit for the [Cache::LRU](https://metacpan.org/pod/Cache%3A%3ALRU) object.
    The maximum number of previous requests responses to be kept in memory.

- respect\_api\_frequency => BOOL

    `default: 1`

    As every _OpenExchangeRates API_ [subscription plan](https://openexchangerates.org/signup) comes with
    its own number of permitted requests per month and resources update frequency. This option is made purely
    to allow your program to query repeated requests without overwhelming API. If the request is already cached meaning we already have its
    response from a previous request invocation, it will check on the current resources `update_frequency` from `usage.json`
    API call, if the `Last-Modified` timestamp HTTP header that is attached with our existing response compared to current time is less
    than `update_frequency` then most probably even if we call the API it will return `304 HTTP`, hence in this case
    respect the API and instead of requesting it to confirm, return the response we already have without requesting again.

    Suitable for repeated requests, and using a restricted subscription plan.

- enable\_pre\_validation => BOOL

    `default: 1`

    Mainly requested currencies, date/time values along with other limitations for some endpoints.
    These options are here to toggle whether to validate those parameters before requesting them or not.

- local\_conversion => BOOL

    `default: 1`

    Given that `convert` API endpoint is only available for Unlimited subscription plan,
    this option is to allow your program to perform conversion function locally, without applying any formatting
    to calculated amount. Not that if you want to use the API instead for ["convert"](#convert) method you need to pass this as `0`

- keep\_http\_response => BOOL

    `default: 1`

    Used to allow your program to access the complete [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) from the last
    API request made through ["last\_http\_response"](#last_http_response). If turned of by passing `0` last\_http\_response will stay empty.

# METHODS

All available methods are `async/await` following [Future::AsyncAwait](https://metacpan.org/pod/Future%3A%3AAsyncAwait) and [Future](https://metacpan.org/pod/Future)

## do\_request

    await $exch->do_request($page, %args);

The generic method to perform HTTP request for any _OpenExchangeRates API_ endpoint.
It has the gist of the logic, from trying to check Cache if the request has been made before
to actually triggering the request and parse its response. Takes to main arguments:

- $page

    as in the endpoint name that needs to be requested.

- %args

    A hash containing the named parameters to be passed as query parameters to the API call URI.

use only when you want parse the complete request yourself, you should be able to get all whats needed from API
using other methods.

## latest

    await $exch->latest();
    await $exch->latest('USD', 'CAD', ['JPY']);

To request [latest.json enpoint](https://docs.openexchangerates.org/reference/latest-json) from API.
It accepts a list, `ARRAYref` or a mixture of both for currencies as an argument where:

- $base currency

    as the **first** param where its `default: 'USD'`

- @symbols

    the rest of the list as symbols to be filtered.

Note that `show_alternative` is always passed as `true` to the API.

## historical

    await $exch->historical($date, $base, @symbols);
    await $exch->historical('2024-04-04', 'CAD');

To request [historical/\*.json endpoint](https://docs.openexchangerates.org/reference/historical-json) from API.
Used to retrieve old rates, takes multiple parameters:

- $date

    required parameter; scalar string following a date format `YYYY-MM-DD`

- $base

    base currency to be used with the request, `default: 'USD'`.

- @symbols

    the rest of parameters will be taken the list of symbols to be filtered out.
    Can be passed as a flat list, an `ARRAYref` or mix of both.

note that show alternative is always on.

## currencies

    await $exch->currencies();
    # to list inactive currencies
    await $exch->currencies(0, 1);

To request [currencies.json endpoint](https://docs.openexchangerates.org/reference/currencies-json) from API.
it mainly returns list of offered currencies by _OpenExchangeRates API_.
takes two optional parameters:

- $show\_alternative

    passed as `0` or `1`, donating to include alternative currencies or not.

- $show\_inactive

    passed as `0` or `1`, donating to list inactive currencies or not.

## time\_series

    await $exch->time_series($start, $end, $base, @symbols);
    await $exch->time_series('2024-04-02', '2024-04-04');

To request [time-series.json endpoint](https://docs.openexchangerates.org/reference/time-series-json) from API.
Essentially its multiple historical requests just handled by _OpenExchangeRates API_ itself. Takes a couple of
parameters:

- $start

    Required start date of the period needed. Following `YYYY-MM-DD` format.

- $end

    Required end date of the period needed. Following `YYYY-MM-DD` format.

- $base

    Base currency for the prices requested. `default: 'USD'`

- @symbols

    Symbols to be filtered out, can be passed as a flat list list or an `ARRAYref`

## convert

    await $exch->convert($value, $from, $to, $reverse_convert);
    await $exch->convert(22, 'USD', 'CAD');
    await $exch->convert(22, 'JPY', 'USD', 1);

To request [convert endpoint](https://docs.openexchangerates.org/reference/convert) from API.
This endpoint is only available in Unlimited subscription plan, however you can enable ["local\_conversion"](#local_conversion)
which will allow you to perform conversion operation locally, applying a simple math equation with no formatting to returned value
so make sure to apply your own decimal point limit to returned value. Accepts these parameters:

- $value

    The amount you'd like to be converted. keep in mind that _OpenExchangeRates API_ only accepts `INT` values.
    However enabling ["local\_conversion"](#local_conversion) will accept none integer values too and be able to convert it.

- $from

    The currency of the `$value` passed above, passed as three characters.

- $to

    The currency to be converted to.

- $reverse\_convert

    This is used when ["local\_conversion"](#local_conversion) is enabled, in order to overcome another restriction on API.
    Which is to get the prices of base currencies other than `USD`. Set it to `1` when you want to make it to use `$to`
    for base to convert, and let it be as `default: 0` to use `$from` currency as the base to convert.

In order for ["local\_conversion"](#local_conversion) to work properly with Free subscription plans, one of the currencies has to be `USD`
where you'd set ["$reverse\_convert"](#reverse_convert) to `1` when you are converting `$to` `USD` rather than `$from`.

## ohlc

    await $exch->ohlc($date, $time, $period, $base, @symbols);
    await $exch->ohlc('2024-04-04', '02:00', '2m');

To request [ohlc.json endpoint](https://docs.openexchangerates.org/reference/ohlc-json) from API.
Retrieving OHLC data requires some parameters to be present which are:

- $date

    Date for selection timeframe needed, follows `YYYY-MM-DD` format.

- $time

    Time for selection timeframe needed, follows `hh:mm` or `h:m`.
    All timings would be based on UTC, as thats what API supports.

- $period

    Period of OHLC needed, like: `'1m'`, `'12h`, `'1d'`, and so on.

- $base

    Optional base currency, `default: 'USD'`

- @symbols

    Optional list of symbols to filter result based on.

## usage

    await $exch->usage();

To request [usage.json endpoint](https://docs.openexchangerates.org/reference/usage-json) from API.
returning both subscription plan details and app\_id API usage so far, along with current app status.

## app\_plan

    await $exch->app_plan();
    await $exch->app_plan($key);

Retrieves only the subscription plan details from ["usage"](#usage) call, with the possibility of passing:

- $key

    to get a specific key value from subscription plan details.

## app\_usage

    await $exch->app_usage();
    await $exch->app_usage($key);

Retrieves only the application current API usage section from ["usage"](#usage) method.

- $key

    A specific key to get value for from API usage.

## app\_features

    await $exch->app_features();
    await $exch->app_features($key);

Retrieves the features that are currently enabled for current `app_id`, accepts:

- $key

    as a specific feature, in order to know whether its enabled or not by API

## app\_status

    await $exch->app_status();

Gets the current `app_id` status on the API, originally in ["usage"](#usage) call.

## plan\_update\_frequency

    await $open_exch_api->plan_update_frequency();

used in order to specifically retrieve the subscription plan update\_frequency in seconds.
Which is the rate that data are refreshed on current active plan.

# FIELD ACCESSORS

No real difference between the other typical methods except that they are not async/await.
Also for most of them they will only be populated after the first request.

## last\_http\_response

    $exch->last_http_response();

Used to access the complete [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) for the last request that has been made.

## app\_id

    $exch->app_id();

The current `APP_ID` that is registered with this instance.

## api\_query\_params

    $exch->api_query_params();

Referenece of the list of parameters accepted by API.

## app\_plan\_keys

    $exch->app_plan_keys();

To get list of subscription plan response hash keys from ["usage"](#usage) call.

## app\_usage\_keys

    $exch->app_usage_keys();

To get list of current API usage response hash keys from ["usage"](#usage) call.

## app\_features\_keys

    $exch->app_features_keys();

To get list of available API features.

# INHERITED METHODS

- [IO::Async::Notifier](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier)

    [add\_child](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#add_child), [adopt\_future](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#adopt_future), [adopted\_futures](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#adopted_futures), [can\_event](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#can_event), [children](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#children), [configure](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#configure), [debug\_printf](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#debug_printf), [get\_loop](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#get_loop), [invoke\_error](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#invoke_error), [invoke\_event](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#invoke_event), [loop](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#loop), [make\_event\_cb](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#make_event_cb), [maybe\_invoke\_event](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#maybe_invoke_event), [maybe\_make\_event\_cb](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#maybe_make_event_cb), [new](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#new), [notifier\_name](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#notifier_name), [parent](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#parent), [remove\_child](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#remove_child), [remove\_from\_parent](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ANotifier#remove_from_parent)
