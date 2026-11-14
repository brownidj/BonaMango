"""Focused startup checks; run manually under the project verification policy."""
import errno
from pathlib import Path
import unittest
from unittest.mock import patch, Mock

import restaurant_server as server


class ServerStartupTests(unittest.TestCase):
    def test_matches_default_service(self):
        self.assertTrue(server.matches_service(
            ['python3', '-u', 'restaurant_server.py'], server.ROOT, 8776,
            server.ROOT / 'data/restaurants.sqlite3'))

    def test_rejects_other_project(self):
        self.assertFalse(server.matches_service(
            ['python3', 'restaurant_server.py'], Path('/tmp/other-project'), 8776,
            server.ROOT / 'data/restaurants.sqlite3'))

    def test_rejects_other_database(self):
        self.assertFalse(server.matches_service(
            ['python3', 'restaurant_server.py', '--db', '/tmp/other.sqlite3'],
            server.ROOT, 8776, server.ROOT / 'data/restaurants.sqlite3'))

    def test_matches_custom_options(self):
        self.assertTrue(server.matches_service(
            ['python3', str(server.ROOT / 'restaurant_server.py'),
             '--db=data/restaurants.sqlite3', '--port', '8777'],
            server.ROOT, 8777, server.ROOT / 'data/restaurants.sqlite3'))

    def test_rejects_unknown_invocations(self):
        for command in [
            ['python3', '-m', 'restaurant_server'],
            ['python3', 'restaurant_server.py', '--unknown'],
            ['python3', 'restaurant_server.py', '--port', '8777'],
            ['other-app', 'restaurant_server.py'],
        ]:
            with self.subTest(command=command):
                self.assertFalse(server.matches_service(command, server.ROOT, 8776,
                                                       server.ROOT / 'data/restaurants.sqlite3'))

    def test_foreign_listener_is_not_replaced(self):
        with patch.object(server, 'RestaurantServer', side_effect=OSError(errno.EADDRINUSE, 'busy')), \
                patch.object(server, 'release_previous_service', return_value=False):
            with self.assertRaisesRegex(RuntimeError, 'occupied by another program'):
                server.start_server(8776, Path('/tmp/data.sqlite3'))

    def test_verified_previous_service_is_replaced_once(self):
        replacement = Mock()
        with patch.object(server, 'RestaurantServer', side_effect=[
                OSError(errno.EADDRINUSE, 'busy'), replacement]) as constructor, \
                patch.object(server, 'release_previous_service', return_value=True):
            self.assertIs(server.start_server(8776, Path('/tmp/data.sqlite3')), replacement)
            self.assertEqual(constructor.call_count, 2)

    def test_non_conflict_error_does_not_stop_any_service(self):
        with patch.object(server, 'RestaurantServer', side_effect=PermissionError(errno.EACCES, 'denied')), \
                patch.object(server, 'release_previous_service') as release:
            with self.assertRaises(PermissionError):
                server.start_server(8776, Path('/tmp/data.sqlite3'))
            release.assert_not_called()

    def test_multiple_verified_old_listeners_are_drained(self):
        replacement = Mock()
        with patch.object(server, 'RestaurantServer', side_effect=[
                OSError(errno.EADDRINUSE, 'busy'), OSError(errno.EADDRINUSE, 'busy'), replacement]), \
                patch.object(server, 'release_previous_service', return_value=True) as release:
            self.assertIs(server.start_server(8776, Path('/tmp/data.sqlite3'), lan=True), replacement)
            self.assertEqual(release.call_count, 2)

    def test_launcher_rejects_bad_devices_before_preparation(self):
        import subprocess
        for args in [[], ['-d'], ['-d', 'PHONE_ID'],
                     ['-d', './scripts/run_mobile.zsh', '-d', 'PHONE_ID']]:
            with self.subTest(args=args):
                result = subprocess.run(['zsh', str(server.ROOT / 'scripts/run_mobile.zsh'), *args],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertNotIn('mobile service', result.stdout + result.stderr)
