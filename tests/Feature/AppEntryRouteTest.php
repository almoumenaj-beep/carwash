<?php

namespace Tests\Feature;

use Tests\TestCase;

class AppEntryRouteTest extends TestCase
{
    public function test_app_entry_redirects_to_the_index_file_without_looping(): void
    {
        $this->get('/app')->assertRedirect('/app/index.html');
    }
}
