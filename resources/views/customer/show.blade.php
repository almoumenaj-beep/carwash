@php
    /** @var \App\Domain\Platform\Models\Tenant $tenant */
    $ar = $tenant->locale === 'ar';
    $dir = $ar ? 'rtl' : 'ltr';
    $t = [
        'services' => $ar ? 'خدماتنا' : 'Our services',
        'offers' => $ar ? 'العروض' : 'Offers',
        'noOffers' => $ar ? 'لا عروض حالياً' : 'No offers at the moment',
        'book' => $ar ? 'احجز موعدك' : 'Book your visit',
        'bookHint' => $ar ? 'اختر الوقت المناسب ونستقبل سيارتك' : 'Pick a time and we will take it from there',
        'name' => $ar ? 'الاسم' : 'Your name',
        'phone' => $ar ? 'رقم الجوال' : 'Phone number',
        'branch' => $ar ? 'الفرع' : 'Branch',
        'size' => $ar ? 'حجم السيارة' : 'Vehicle size',
        'anySize' => $ar ? 'غير محدد' : 'Not sure',
        'service' => $ar ? 'الخدمة' : 'Service',
        'anyService' => $ar ? 'أحددها في المغسلة' : 'Decide at the car wash',
        'plate' => $ar ? 'رقم اللوحة (اختياري)' : 'Plate number (optional)',
        'date' => $ar ? 'التاريخ' : 'Date',
        'time' => $ar ? 'الوقت' : 'Time',
        'pickTime' => $ar ? 'اختر التاريخ أولاً' : 'Pick a date first',
        'noSlots' => $ar ? 'لا أوقات متاحة في هذا اليوم' : 'No times available that day',
        'notes' => $ar ? 'ملاحظات (اختياري)' : 'Notes (optional)',
        'submit' => $ar ? 'تأكيد الحجز' : 'Confirm the booking',
        'booked' => $ar ? 'تم حجز موعدك بنجاح. نراك قريباً!' : 'Your appointment is booked. See you soon!',
        'errors' => $ar ? 'يرجى تصحيح ما يلي:' : 'Please fix the following:',
        'expires' => $ar ? 'حتى' : 'Until',
        'minutes' => $ar ? 'دقيقة' : 'min',
        'contact' => $ar ? 'تواصل معنا' : 'Contact us',
        'rights' => $ar ? 'جميع الحقوق محفوظة' : 'All rights reserved',
        'slogan' => $ar ? 'غسيل احترافي وعناية كاملة بسيارتك' : 'A professional wash and complete care for your car',
    ];
    $money = function (int $amount) use ($tenant): string {
        $decimals = $tenant->currencyDecimals();
        return rtrim(rtrim(number_format($amount / (10 ** $decimals), $decimals), '0'), '.').' '.$tenant->currency;
    };
    $today = \Carbon\CarbonImmutable::today($tenant->timezone)->toDateString();
@endphp
<!DOCTYPE html>
<html lang="{{ $tenant->locale }}" dir="{{ $dir }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $tenant->name }}</title>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800;900&family=Reem+Kufi:wght@600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --gold: #c8a24b;
            --gold-d: #a5842f;
            --gold-l: #f4ead2;
            --navy: #16233d;
            --navy-2: #3d5273;
            --cream: #f8f5ef;
            --sand: #efe7d8;
            --paper: #fff;
            --ink: #1a1f2b;
            --muted: #7d8494;
            --line: #e8e2d4;
            --danger: #b3261e;
            --radius: 20px;
            --shadow: 0 4px 14px rgba(22, 35, 61, .08);
            --display: 'Reem Kufi', 'Cairo', sans-serif;
        }
        * { box-sizing: border-box; }
        html { scroll-behavior: smooth; }
        .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
        body { margin: 0; font-family: 'Cairo', Tahoma, Arial, sans-serif; background: var(--cream); color: var(--ink); }
        h1, h2, h3 { font-family: var(--display); }

        /* الشريط العلوي */
        .top {
            display: flex; align-items: center; gap: 12px; padding: 12px 16px;
            background: var(--paper); position: sticky; top: 0; z-index: 30;
            border-bottom: 1px solid var(--line);
        }
        .brand { display: flex; align-items: center; gap: 10px; font-family: var(--display); font-weight: 700; font-size: 1.15rem; color: var(--navy); text-decoration: none; }
        .brand b { color: var(--gold-d); }
        .top-logo { height: 44px; width: auto; border-radius: 10px; box-shadow: 0 2px 8px rgba(22, 35, 61, .18); }
        .top-nav { display: flex; gap: 4px; margin-inline-start: auto; overflow-x: auto; scrollbar-width: none; }
        .top-nav::-webkit-scrollbar { display: none; }
        .top-nav a { padding: 8px 16px; border-radius: 999px; font-weight: 700; color: var(--muted); text-decoration: none; white-space: nowrap; }
        .top-nav a:hover { background: var(--sand); color: var(--ink); }
        .top-nav a.cta { background: var(--navy); color: #fff; }
        .top-nav a.cta:hover { background: var(--navy-2); }

        /* الواجهة الرئيسية */
        .brand-hero { position: relative; overflow: hidden; color: var(--ink); background:
            radial-gradient(75% 95% at 50% 0%, var(--gold-l) 0, rgba(244, 234, 210, .35) 55%, transparent 78%),
            var(--cream);
        }
        .brand-hero-inner {
            position: relative; max-width: 1120px; margin: 0 auto;
            padding: clamp(26px, 6vw, 52px) 16px;
            display: grid; justify-items: center; text-align: center; gap: clamp(8px, 2vw, 14px);
        }
        .brand-hero h1 { margin: 0; font-size: clamp(2rem, 6vw, 3.2rem); color: var(--navy); }
        .brand-hero p { margin: 0; color: var(--muted); font-size: 1.05rem; font-weight: 600; }
        .hero-logo {
            width: clamp(240px, 62vw, 420px); height: auto; border-radius: 16px;
            box-shadow: 0 10px 30px rgba(22, 35, 61, .22), 0 0 0 6px var(--paper), 0 0 0 8px var(--gold);
        }

        .page { max-width: 1120px; margin: 0 auto; padding: 0 16px; }
        .block { padding: 18px 0 6px; scroll-margin-top: 76px; }
        .block-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 12px; }
        .block-head h2 { display: flex; align-items: center; gap: 10px; margin: 0; color: var(--navy); font-size: 1.35rem; }
        .block-head h2::before {
            content: ''; width: 18px; height: 18px; border-radius: 5px; flex: none;
            background: linear-gradient(135deg, var(--gold) 50%, var(--navy) 50%);
        }

        /* السكة الأفقية وبطاقاتها (نمط «اخترنا لك») */
        .rail { display: grid; grid-auto-flow: column; grid-auto-columns: 44%; gap: 12px; overflow-x: auto; scroll-snap-type: x mandatory; padding-bottom: 6px; scrollbar-width: none; }
        .rail::-webkit-scrollbar { display: none; }
        @media (min-width: 560px) { .rail { grid-auto-columns: 31%; } }
        @media (min-width: 900px) { .rail { grid-auto-columns: 23%; } }
        @media (min-width: 1200px) { .rail { grid-auto-columns: 18.5%; } }
        .rail-card {
            scroll-snap-align: start; display: flex; flex-direction: column;
            background: var(--paper); border: 1px solid var(--line);
            border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow);
        }
        .card-photo {
            position: relative; display: grid; place-items: center; aspect-ratio: 1; width: 100%;
            background: radial-gradient(circle at 50% 40%, #fff 0, var(--sand) 75%);
        }
        .card-ico {
            display: grid; place-items: center; width: 56%; aspect-ratio: 1; border-radius: 50%;
            font-size: clamp(40px, 6vw, 64px); line-height: 1; background: var(--paper);
            border: 2px solid var(--gold-l); box-shadow: 0 8px 18px rgba(22, 35, 61, .10);
        }
        .card-name { padding: 10px 12px 0; font-weight: 800; font-size: .98rem; line-height: 1.35; color: var(--navy); }
        .card-hint { padding: 2px 12px 0; font-size: .78rem; color: var(--muted); line-height: 1.4; }
        .card-price { padding: 4px 12px 12px; color: var(--gold-d); font-weight: 900; margin-top: auto; }
        .card-price small { color: var(--muted); font-weight: 600; }
        .price-line { display: flex; justify-content: space-between; align-items: baseline; gap: 8px; padding: 1px 0; }
        .offer-ends-tag {
            position: absolute; bottom: 8px; inset-inline-start: 8px; max-width: calc(100% - 16px);
            font-size: .72rem; font-weight: 800; line-height: 1.3; padding: 2px 8px; border-radius: 999px;
            color: #9a3412; background: rgba(255, 237, 213, .95);
        }
        .rail-dots { display: flex; justify-content: center; gap: 6px; padding: 8px 0 2px; }
        .rail-dots i { width: 7px; height: 7px; border-radius: 50%; background: var(--line); transition: background .2s; }
        .rail-dots i.on { background: var(--gold); }

        /* نموذج الحجز */
        form.card {
            display: flex; flex-direction: column; gap: 12px; padding: 18px;
            background: var(--paper); border: 1px solid var(--line); border-bottom: 4px solid var(--gold);
            border-radius: var(--radius); box-shadow: var(--shadow);
        }
        .row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        @media (max-width: 560px) { .row { grid-template-columns: 1fr; } .rail { grid-auto-columns: 78%; } }
        label { display: grid; gap: 4px; font-size: .82rem; font-weight: 700; color: var(--navy-2); }
        input, select, textarea {
            font: inherit; padding: 10px 14px; border: 1px solid var(--line); border-radius: 12px;
            background: var(--cream); color: var(--ink); width: 100%;
        }
        input:focus, select:focus, textarea:focus { outline: 2px solid var(--gold); border-color: transparent; background: var(--paper); }
        textarea { resize: vertical; }
        button.submit {
            border: none; cursor: pointer; padding: 13px; font: inherit; font-weight: 800; font-size: 1.02rem;
            border-radius: 14px; color: #fff; background: linear-gradient(135deg, var(--navy) 0%, var(--navy-2) 100%);
        }
        button.submit:hover { filter: brightness(1.12); }
        .banner { background: var(--gold-l); border: 1px solid var(--gold); color: var(--gold-d); font-weight: 700; padding: 12px 16px; border-radius: var(--radius); margin-top: 18px; }
        .errors { background: #fdecec; border: 1px solid #f3b2b2; color: var(--danger); padding: 12px 16px; border-radius: var(--radius); margin-top: 18px; font-size: .88rem; }
        .errors ul { margin: 6px 0 0; padding-inline-start: 20px; }

        /* التذييل */
        .foot { background: var(--paper); border-top: 1px solid var(--line); margin-top: 28px; }
        .foot-inner { max-width: 1120px; margin: 0 auto; padding: 22px 16px 8px; display: grid; gap: 10px; text-align: center; }
        .foot h3 { margin: 0; font-size: 1rem; color: var(--navy); }
        .foot p { margin: 0; color: var(--muted); font-size: .9rem; }
        .foot-note { text-align: center; color: var(--muted); font-size: .82rem; margin: 0; padding: 10px 16px 18px; }
    </style>
</head>
<body>

<header class="top">
    <a class="brand" href="#top">
        <img src="{{ url('brand-logo.png') }}" alt="{{ $tenant->name }}" class="top-logo">
        {{ $tenant->name }}
    </a>
    <nav class="top-nav">
        <a href="#services">{{ $t['services'] }}</a>
        @if($offers->isNotEmpty())<a href="#offers">{{ $t['offers'] }}</a>@endif
        <a href="#contact">{{ $t['contact'] }}</a>
        <a href="#book" class="cta">{{ $t['book'] }}</a>
    </nav>
</header>

<section class="brand-hero" id="top">
    <div class="brand-hero-inner">
        <img class="hero-logo" src="{{ url('brand-logo.png') }}" alt="{{ $tenant->name }}">
        <h1 class="sr-only">{{ $tenant->name }}</h1>
        <p>{{ $t['slogan'] }}</p>
    </div>
</section>

<main class="page">
    @if(session('booked'))<div class="banner">{{ session('booked') }}</div>@endif
    @if($errors->any())
        <div class="errors">
            {{ $t['errors'] }}
            <ul>@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul>
        </div>
    @endif

    @if($offers->isNotEmpty())
        <section class="block" id="offers">
            <div class="block-head"><h2>{{ $t['offers'] }}</h2></div>
            <div class="rail" data-rail>
                @foreach($offers as $offer)
                    <article class="rail-card">
                        <span class="card-photo">
                            <span class="card-ico">⭐</span>
                            @if($offer->expires_on)<span class="offer-ends-tag">{{ $t['expires'] }} {{ $offer->expires_on->toDateString() }}</span>@endif
                        </span>
                        <span class="card-name">{{ $offer->title }}</span>
                        @if($offer->description)<span class="card-hint">{{ $offer->description }}</span>@endif
                        @if($offer->price !== null)<span class="card-price">{{ $money($offer->price) }}</span>@endif
                    </article>
                @endforeach
            </div>
            <div class="rail-dots" data-dots></div>
        </section>
    @endif

    <section class="block" id="services">
        <div class="block-head"><h2>{{ $t['services'] }}</h2></div>
        @foreach($services as $group)
            @if($group['category'] !== '')
                <div class="block-head" style="margin-top:10px"><h2 style="font-size:1.05rem">{{ $group['category'] }}</h2></div>
            @endif
            <div class="rail" data-rail>
                @foreach($group['services'] as $index => $service)
                    <article class="rail-card">
                        <span class="card-photo"><span class="card-ico">{{ ['🚗', '💧', '🧽', '✨', '🛞', '🚿', '🫧', '🌟'][$index % 8] }}</span></span>
                        <span class="card-name">{{ $service['name'] }}</span>
                        <span class="card-price">
                            @foreach($service['prices'] as $price)
                                <div class="price-line"><small>{{ $price['size'] }}</small>{{ $money($price['price']) }}</div>
                            @endforeach
                        </span>
                    </article>
                @endforeach
            </div>
            <div class="rail-dots" data-dots></div>
        @endforeach
    </section>

    <section class="block" id="book">
        <div class="block-head"><h2>{{ $t['book'] }}</h2></div>
        <form class="card" method="post" action="{{ route('customer.book', $tenant) }}">
            @csrf
            <div class="row">
                <label>{{ $t['name'] }}<input name="customer_name" required maxlength="100" value="{{ old('customer_name') }}"></label>
                <label>{{ $t['phone'] }}<input name="customer_phone" required dir="ltr" value="{{ old('customer_phone') }}"></label>
            </div>
            @if($branches->count() > 1)
                <label>{{ $t['branch'] }}
                    <select name="branch_id" id="branch">
                        @foreach($branches as $branch)<option value="{{ $branch->id }}" @selected(old('branch_id') === $branch->id)>{{ $branch->name }}</option>@endforeach
                    </select>
                </label>
            @else
                <input type="hidden" name="branch_id" id="branch" value="{{ $branches->first()?->id }}">
            @endif
            <div class="row">
                <label>{{ $t['size'] }}
                    <select name="vehicle_size_id">
                        <option value="">{{ $t['anySize'] }}</option>
                        @foreach($sizes as $size)<option value="{{ $size->id }}" @selected(old('vehicle_size_id') === $size->id)>{{ $size->name }}</option>@endforeach
                    </select>
                </label>
                <label>{{ $t['service'] }}
                    <select name="service_id">
                        <option value="">{{ $t['anyService'] }}</option>
                        @foreach($services as $group)
                            @foreach($group['services'] as $service)
                                <option value="{{ $service['id'] }}" @selected(old('service_id') === $service['id'])>{{ $service['name'] }}</option>
                            @endforeach
                        @endforeach
                    </select>
                </label>
            </div>
            <label>{{ $t['plate'] }}<input name="plate_number" maxlength="20" dir="ltr" value="{{ old('plate_number') }}"></label>
            <div class="row">
                <label>{{ $t['date'] }}<input type="date" name="date" id="date" min="{{ $today }}" value="{{ old('date', $today) }}" required></label>
                <label>{{ $t['time'] }}
                    <select name="starts_at" id="time" required>
                        <option value="">{{ $t['pickTime'] }}</option>
                    </select>
                </label>
            </div>
            <label>{{ $t['notes'] }}<textarea name="notes" rows="2" maxlength="1000">{{ old('notes') }}</textarea></label>
            <button type="submit" class="submit">{{ $t['submit'] }}</button>
        </form>
    </section>
</main>

<footer class="foot" id="contact">
    <div class="foot-inner">
        <h3>{{ $t['contact'] }}</h3>
        @foreach($branches as $branch)
            <p>{{ $branch->name }} — {{ $branch->address }}@if($branch->phone) · <span dir="ltr">{{ $branch->phone }}</span>@endif</p>
        @endforeach
    </div>
    <p class="foot-note">© {{ date('Y') }} {{ $tenant->name }} — {{ $t['rights'] }}</p>
</footer>

<script>
    const branch = document.getElementById('branch');
    const date = document.getElementById('date');
    const time = document.getElementById('time');
    const pickTime = @json($t['pickTime']);
    const noSlots = @json($t['noSlots']);
    const slotsUrl = @json(route('customer.slots', $tenant));

    async function loadSlots() {
        time.innerHTML = '';
        if (!branch.value || !date.value) {
            time.add(new Option(pickTime, ''));
            return;
        }
        time.add(new Option('…', ''));
        const url = slotsUrl + '?branch_id=' + encodeURIComponent(branch.value) + '&date=' + encodeURIComponent(date.value);
        const slots = await (await fetch(url)).json();
        time.innerHTML = '';
        if (!slots.data.length) {
            time.add(new Option(noSlots, ''));
            return;
        }
        for (const slot of slots.data) {
            time.add(new Option(slot.time, slot.starts_at));
        }
    }

    branch.addEventListener('change', loadSlots);
    date.addEventListener('change', loadSlots);
    loadSlots();

    // نقاط تنقّل تحت كل سكة، تظهر فقط إذا البوكسات أكثر من المعروض
    document.querySelectorAll('[data-rail]').forEach((rail) => {
        const dotsBox = rail.nextElementSibling;
        if (dotsBox === null || !dotsBox.hasAttribute('data-dots')) {
            return;
        }

        const step = () => rail.scrollWidth / rail.children.length;
        const visible = () => Math.max(1, Math.round(rail.clientWidth / step()));
        const pages = () => Math.max(0, rail.children.length - visible() + 1);

        const draw = () => {
            const count = pages();
            dotsBox.innerHTML = '';
            if (count <= 1) {
                return;
            }
            for (let i = 0; i < count; i++) {
                dotsBox.appendChild(document.createElement('i'));
            }
            paint();
        };

        const paint = () => {
            const max = rail.scrollWidth - rail.clientWidth;
            const ratio = max > 0 ? Math.abs(rail.scrollLeft) / max : 0;
            const active = Math.round(ratio * (pages() - 1));
            [...dotsBox.children].forEach((dot, i) => dot.classList.toggle('on', i === active));
        };

        rail.addEventListener('scroll', paint, { passive: true });
        window.addEventListener('resize', draw);
        draw();
    });
</script>
</body>
</html>
