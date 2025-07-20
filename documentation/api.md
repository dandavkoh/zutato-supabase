# API Documentation

## 🔗 Supabase Client Setup

### Installation
```bash
npm install @supabase/supabase-js
```

### Client Initialisierung
```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://127.0.0.1:54321' // Lokal
// const supabaseUrl = 'https://your-project.supabase.co' // Produktion

const supabaseAnonKey = 'your-anon-key'

const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

## 🔐 Authentication

### Benutzer registrieren
```javascript
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password123'
})

if (error) {
  console.error('Registration error:', error.message)
} else {
  console.log('User registered:', data.user)
}
```

### Benutzer anmelden
```javascript
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123'
})

if (error) {
  console.error('Login error:', error.message)
} else {
  console.log('User logged in:', data.user)
  // Token ist automatisch gespeichert
}
```

### Benutzer abmelden
```javascript
const { error } = await supabase.auth.signOut()

if (error) {
  console.error('Logout error:', error.message)
} else {
  console.log('User logged out')
}
```

### Aktuellen Benutzer abrufen
```javascript
const { data: { user }, error } = await supabase.auth.getUser()

if (error) {
  console.error('Error getting user:', error.message)
} else {
  console.log('Current user:', user)
}
```

### Session-Status überwachen
```javascript
supabase.auth.onAuthStateChange((event, session) => {
  console.log('Auth state changed:', event, session?.user?.email)
})
```

## 📊 Datenbank-Operationen

### Listen abrufen
```javascript
// Alle Listen des Benutzers
const { data: lists, error } = await supabase
  .from('lists')
  .select('*')
  .eq('is_deleted', false)

if (error) {
  console.error('Error fetching lists:', error.message)
} else {
  console.log('Lists:', lists)
}
```

### Liste erstellen
```javascript
const { data: list, error } = await supabase
  .from('lists')
  .insert([
    {
      name: 'Wocheneinkauf',
      description: 'Einkaufsliste für diese Woche'
    }
  ])
  .select()

if (error) {
  console.error('Error creating list:', error.message)
} else {
  console.log('List created:', list[0])
}
```

### Liste aktualisieren
```javascript
const { data: list, error } = await supabase
  .from('lists')
  .update({ name: 'Neuer Name' })
  .eq('id', 'list-uuid')
  .select()

if (error) {
  console.error('Error updating list:', error.message)
} else {
  console.log('List updated:', list[0])
}
```

### Liste löschen (Soft Delete)
```javascript
const { error } = await supabase
  .from('lists')
  .update({ 
    is_deleted: true, 
    deleted_at: new Date().toISOString() 
  })
  .eq('id', 'list-uuid')

if (error) {
  console.error('Error deleting list:', error.message)
} else {
  console.log('List deleted')
}
```

### Einkaufsartikel abrufen
```javascript
// Artikel einer Liste mit Details
const { data: items, error } = await supabase
  .from('shopping_items')
  .select(`
    *,
    categories(name, icon),
    units(name, short_name)
  `)
  .eq('list_id', 'list-uuid')
  .eq('is_deleted', false)
  .order('created_at', { ascending: false })

if (error) {
  console.error('Error fetching items:', error.message)
} else {
  console.log('Items:', items)
}
```

### Artikel erstellen
```javascript
const { data: item, error } = await supabase
  .from('shopping_items')
  .insert([
    {
      list_id: 'list-uuid',
      name: 'Äpfel',
      quantity: 5,
      unit_id: 'unit-uuid',
      category_id: 'category-uuid',
      notes: 'Bio-Äpfel bevorzugt'
    }
  ])
  .select()

if (error) {
  console.error('Error creating item:', error.message)
} else {
  console.log('Item created:', item[0])
}
```

### Artikel als erledigt markieren
```javascript
const { data: item, error } = await supabase
  .from('shopping_items')
  .update({ 
    is_completed: true,
    completed_at: new Date().toISOString()
  })
  .eq('id', 'item-uuid')
  .select()

if (error) {
  console.error('Error updating item:', error.message)
} else {
  console.log('Item completed:', item[0])
}
```

## 👥 Listen-Mitglieder

### Mitglieder einer Liste abrufen
```javascript
const { data: members, error } = await supabase
  .from('list_members')
  .select(`
    *,
    auth.users(email)
  `)
  .eq('list_id', 'list-uuid')

if (error) {
  console.error('Error fetching members:', error.message)
} else {
  console.log('Members:', members)
}
```

### Mitglied zu Liste hinzufügen
```javascript
const { data: member, error } = await supabase
  .from('list_members')
  .insert([
    {
      list_id: 'list-uuid',
      user_id: 'user-uuid',
      role: 'editor'
    }
  ])
  .select()

if (error) {
  console.error('Error adding member:', error.message)
} else {
  console.log('Member added:', member[0])
}
```

## 📋 Kategorien und Einheiten

### Kategorien abrufen
```javascript
const { data: categories, error } = await supabase
  .from('categories')
  .select('*')
  .order('name')

if (error) {
  console.error('Error fetching categories:', error.message)
} else {
  console.log('Categories:', categories)
}
```

### Einheiten abrufen
```javascript
const { data: units, error } = await supabase
  .from('units')
  .select('*')
  .order('name')

if (error) {
  console.error('Error fetching units:', error.message)
} else {
  console.log('Units:', units)
}
```

## 🔍 Erweiterte Queries

### Pagination
```javascript
const { data: lists, error, count } = await supabase
  .from('lists')
  .select('*', { count: 'exact' })
  .range(0, 9) // Erste 10 Einträge

console.log('Total count:', count)
```

### Filtering
```javascript
// Nur erledigte Artikel
const { data: completedItems } = await supabase
  .from('shopping_items')
  .select('*')
  .eq('is_completed', true)
  .eq('list_id', 'list-uuid')

// Artikel nach Kategorie filtern
const { data: itemsByCategory } = await supabase
  .from('shopping_items')
  .select('*')
  .eq('category_id', 'category-uuid')
```

### Sorting
```javascript
// Listen nach Erstellungsdatum sortieren
const { data: lists } = await supabase
  .from('lists')
  .select('*')
  .order('created_at', { ascending: false })

// Artikel nach Name sortieren
const { data: items } = await supabase
  .from('shopping_items')
  .select('*')
  .order('name', { ascending: true })
```

### Joins mit Views
```javascript
// Listen mit Mitgliederanzahl
const { data: listsWithCount } = await supabase
  .from('lists_with_member_count')
  .select('*')

// Artikel mit Details
const { data: itemsWithDetails } = await supabase
  .from('shopping_items_with_details')
  .select('*')
```

## 🚨 Error Handling

### Standard Error Handling
```javascript
const { data, error } = await supabase
  .from('lists')
  .select('*')

if (error) {
  switch (error.code) {
    case 'PGRST116':
      console.error('Row Level Security violation')
      break
    case 'PGRST301':
      console.error('Invalid request')
      break
    default:
      console.error('Database error:', error.message)
  }
} else {
  console.log('Success:', data)
}
```

### Custom Error Handler
```javascript
const handleSupabaseError = (error) => {
  if (error.code === 'PGRST116') {
    return 'Keine Berechtigung für diese Aktion'
  }
  if (error.code === '23505') {
    return 'Eintrag bereits vorhanden'
  }
  return error.message
}

const { data, error } = await supabase
  .from('lists')
  .insert([{ name: 'Test' }])

if (error) {
  const userMessage = handleSupabaseError(error)
  console.error(userMessage)
}
```

## 🔄 Real-time Subscriptions

### Listen in Echtzeit überwachen
```javascript
const subscription = supabase
  .channel('lists_changes')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'lists'
    },
    (payload) => {
      console.log('List changed:', payload)
    }
  )
  .subscribe()

// Subscription beenden
subscription.unsubscribe()
```

### Spezifische Liste überwachen
```javascript
const subscription = supabase
  .channel('list_items')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'shopping_items',
      filter: 'list_id=eq.list-uuid'
    },
    (payload) => {
      console.log('Item changed:', payload)
    }
  )
  .subscribe()
```

## 📝 React/Vue Integration

### React Hook Beispiel
```javascript
import { useState, useEffect } from 'react'
import { supabase } from './supabaseClient'

function useLists() {
  const [lists, setLists] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetchLists()
  }, [])

  const fetchLists = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('lists')
        .select('*')
        .eq('is_deleted', false)

      if (error) throw error
      setLists(data)
    } catch (error) {
      setError(error.message)
    } finally {
      setLoading(false)
    }
  }

  return { lists, loading, error, refetch: fetchLists }
}
```

### Vue Composition API Beispiel
```javascript
import { ref, onMounted } from 'vue'
import { supabase } from './supabaseClient'

export function useLists() {
  const lists = ref([])
  const loading = ref(true)
  const error = ref(null)

  const fetchLists = async () => {
    try {
      loading.value = true
      const { data, error: err } = await supabase
        .from('lists')
        .select('*')
        .eq('is_deleted', false)

      if (err) throw err
      lists.value = data
    } catch (err) {
      error.value = err.message
    } finally {
      loading.value = false
    }
  }

  onMounted(fetchLists)

  return { lists, loading, error, fetchLists }
}
```

## 🔗 Nützliche Links

- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Database](https://supabase.com/docs/guides/database)
- [Supabase Real-time](https://supabase.com/docs/guides/realtime)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security) 