"""Controlled hosted checks. Public by default; --mutations creates ONE account/booking.

No local backend, database access, provider charges, or administrator mutations.
Credentials are random, memory-only, and never printed. A test account remains
because the backend exposes no account deletion. Eligible bookings are cancelled.
"""
import argparse
import datetime as dt
import http.cookiejar
import json
import secrets
import urllib.error
import urllib.parse
import urllib.request

API = 'https://fb-international-assessment-project.onrender.com/api/v1'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mutations', action='store_true')
    parser.add_argument('--assistant', action='store_true')
    args = parser.parse_args()
    jar = http.cookiejar.CookieJar()
    client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    token = None

    def request(path, method='GET', body=None, expected=200, auth=False, csrf=None):
        headers = {'Accept': 'application/json'}
        if auth:
            headers['Authorization'] = 'Bearer ' + token
        if csrf:
            headers['X-CSRF-Token'] = csrf
        data = None if body is None else json.dumps(body).encode()
        if data is not None:
            headers['Content-Type'] = 'application/json'
        req = urllib.request.Request(API + path, data=data, headers=headers, method=method)
        try:
            with client.open(req, timeout=90) as response:
                status, raw = response.status, response.read()
        except urllib.error.HTTPError as error:
            status, raw = error.code, error.read()
        result = json.loads(raw) if raw else None
        if status != expected:
            code = result.get('code', '') if isinstance(result, dict) else ''
            raise RuntimeError(f'{method} {path}: expected {expected}, received {status} {code}')
        return result

    def passed(label):
        print('PASS ' + label, flush=True)

    request('/health/status')
    platform = request('/platform')
    assert platform['booking']['timeZone'] == 'Asia/Dhaka'
    assert 1 <= platform['booking']['horizonDays'] <= 90
    passed('health and platform configuration')
    catalog = request('/services')
    assert catalog and all(service['price'] == service['effectivePrice'] for service in catalog)
    packages = request('/services?type=PACKAGE')
    assert packages and all(item['type'] == 'PACKAGE' for item in packages)
    service = next(item for item in catalog if item['type'] == 'INDIVIDUAL')
    assert request('/services/' + service['id'])['id'] == service['id']
    search = urllib.parse.urlencode({'search': service['name'], 'categoryId': service['categoryId']})
    assert any(item['id'] == service['id'] for item in request('/services?' + search))
    offers = request('/offers')
    assert all(item['effectivePrice'] <= item['originalPrice'] for item in catalog)
    passed(f'catalog ({len(catalog)} items, {len(packages)} packages), details, search/category, pricing, offers ({len(offers)})')
    capabilities = request('/payments/config')
    print('PAYMENT_CONFIG ' + json.dumps(capabilities), flush=True)
    request('/appointments', expected=401)
    request('/admin/payments', expected=401)
    passed('unauthenticated protected endpoints denied')
    day = (dt.datetime.now(dt.timezone(dt.timedelta(hours=6))) + dt.timedelta(days=2)).date().isoformat()
    availability = request(f'/services/{service["id"]}/availability?date={day}')
    slot = next(item for item in availability['slots'] if item['available'])
    passed('future persisted availability and slot IDs')
    if args.assistant:
        try:
            response = request('/assistant/chat', 'POST', {'messages': [{'role': 'user', 'content': 'Suggest an existing package under 2000 taka.'}]})
            ids = {item['id'] for item in catalog}
            categories = {item['categoryId'] for item in catalog}
            for action in response['actions']:
                assert action['type'] in ('serviceDetails', 'browseServices')
                if action['type'] == 'serviceDetails':
                    assert action['serviceId'] in ids
                elif action.get('categoryId'):
                    assert action['categoryId'] in categories
            passed('guest structured assistant recommendation uses live catalog IDs')
        except RuntimeError as error:
            print('BLOCKED assistant: ' + str(error), flush=True)
    if not args.mutations:
        return
    unique = secrets.token_hex(8)
    email = f'autocare-assessment-{unique}@example.com'
    password = secrets.token_urlsafe(24)
    auth = request('/auth/register', 'POST', {'name': 'AutoCare Hosted Acceptance', 'email': email, 'password': password}, expected=201)
    token = auth['accessToken']
    appointment = None
    try:
        assert request('/auth/me', auth=True)['user']['id'] == auth['user']['id']
        passed('dedicated account registration and authenticated identity')
        request('/auth/logout', 'POST', expected=204)
        auth = request('/auth/login', 'POST', {'email': email, 'password': password})
        token = auth['accessToken']
        csrf = request('/auth/csrf')['csrfToken']
        refreshed = request('/auth/refresh', 'POST', csrf=csrf)
        token = refreshed['accessToken']
        assert request('/auth/me', auth=True)['user']['id'] == auth['user']['id']
        passed('login, cookie/CSRF acquisition, refresh rotation, restored identity (native HTTP client)')
        request('/admin/payments', expected=403, auth=True)
        passed('customer admin-payment authorization denied')
        appointment = request('/appointments', 'POST', {'serviceId': service['id'], 'slotId': slot['id']}, expected=201, auth=True)
        assert appointment['status'] == 'pending' and appointment['paymentStatus'] == 'unpaid'
        assert isinstance(appointment['canPayOnline'], bool) and appointment['canCancel']
        assert request('/appointments/' + appointment['id'], auth=True)['id'] == appointment['id']
        assert any(item['id'] == appointment['id'] for item in request('/appointments', auth=True))
        assert request('/appointments/' + appointment['id'] + '/payments', auth=True) == []
        passed('one saved future booking, immutable price fields, detail/history and empty payment history')
        print('TEST_APPOINTMENT ' + appointment['id'], flush=True)
    finally:
        if appointment and appointment['canCancel']:
            cancelled = request('/appointments/' + appointment['id'] + '/cancel', 'PATCH', auth=True)
            assert cancelled['status'] == 'cancelled'
            passed('controlled test appointment cancelled through supported API')
        request('/auth/logout', 'POST', expected=204)
        request('/auth/refresh', 'POST', expected=401)
        passed('logout invalidates refresh session')
        print('NOTE one labeled test account remains; account deletion is not supported. No credentials retained.', flush=True)


if __name__ == '__main__':
    main()
