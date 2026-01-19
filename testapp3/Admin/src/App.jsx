import { useEffect, useState } from 'react'
import {
  collection,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  doc,
  serverTimestamp,
  query,
  orderBy,
  getDoc,
  setDoc,
  where,
} from 'firebase/firestore'
import { db } from './firebase'

function App() {
  const [activeTab, setActiveTab] = useState('overview') // 'overview' | 'users' | 'mealTips' | 'notifications'

  // Meal tips
  const [tips, setTips] = useState([])
  const [tipsLoading, setTipsLoading] = useState(true)
  const [tipsError, setTipsError] = useState('')
  const [form, setForm] = useState({ id: null, title: '', subtitle: '', colorHex: '#FF8A65' })

  // Users
  const [users, setUsers] = useState([])
  const [usersLoading, setUsersLoading] = useState(true)
  const [usersError, setUsersError] = useState('')

  // Meal tips stream
  useEffect(() => {
    const q = query(collection(db, 'mealTips'), orderBy('createdAt', 'asc'))
    const unsub = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }))
        setTips(data)
        setTipsLoading(false)
      },
      (err) => {
        console.error('Failed to load meal tips', err)
        setTipsError('Failed to load meal tips')
        setTipsLoading(false)
      },
    )

    return () => unsub()
  }, [])

  // Users stream (all users; we derive "active hydration" users from waterEnabled)
  useEffect(() => {
    const usersQuery = query(collection(db, 'users'))
    const unsub = onSnapshot(
      usersQuery,
      (snapshot) => {
        const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }))
        setUsers(data)
        setUsersLoading(false)
      },
      (err) => {
        console.error('Failed to load users', err)
        setUsersError('Failed to load users')
        setUsersLoading(false)
      },
    )

    return () => unsub()
  }, [])



  const resetForm = () =>
    setForm({ id: null, title: '', subtitle: '', colorHex: '#FF8A65' })

  const handleChange = (e) => {
    const { name, value } = e.target
    setForm((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const title = form.title.trim()
    const subtitle = form.subtitle.trim()
    const colorHex = form.colorHex.trim() || '#FF8A65'
    
    // Validate title is not empty
    if (!title) {
      setTipsError('Title is required')
      return
    }

    try {
      if (form.id == null) {
        // Adding new tip
        console.log('Adding new meal tip:', { title, subtitle, colorHex })
        const docRef = await addDoc(collection(db, 'mealTips'), {
          title,
          subtitle,
          colorHex,
          createdAt: serverTimestamp(),
        })
        console.log('Meal tip added successfully with ID:', docRef.id)
      } else {
        // Updating existing tip
        console.log('Updating meal tip:', form.id, { title, subtitle, colorHex })
        await updateDoc(doc(db, 'mealTips', form.id), {
          title,
          subtitle,
          colorHex,
        })
        console.log('Meal tip updated successfully')
      }

      resetForm()
      setTipsError('')
    } catch (err) {
      console.error('Failed to save meal tip', err)
      const errorMsg = err.message || 'Failed to save meal tip'
      setTipsError(errorMsg)
    }
  }

  const handleEdit = (tip) => {
    setForm({
      id: tip.id,
      title: tip.title ?? '',
      subtitle: tip.subtitle ?? '',
      colorHex: tip.colorHex ?? '#FF8A65',
    })
  }

  const handleDelete = async (id) => {
    try {
      console.log('Deleting meal tip:', id)
      await deleteDoc(doc(db, 'mealTips', id))
      console.log('Meal tip deleted successfully')
      if (form.id === id) {
        resetForm()
      }
      setTipsError('')
    } catch (err) {
      console.error('Failed to delete meal tip', err)
      const errorMsg = err.message || 'Failed to delete meal tip'
      setTipsError(errorMsg)
    }
  }

  // No global hydration settings to edit anymore, so the
  // corresponding handlers have been removed.

  // Dev-only helper to quickly seed Firestore with a user and a meal tip.
  const injectTestData = async () => {
    try {
      await addDoc(collection(db, 'users'), {
        nickname: 'Test User',
        heightCm: 175,
        weightKg: 70,
        createdAt: serverTimestamp(),
      })

      await addDoc(collection(db, 'mealTips'), {
        title: 'Drink water!',
        subtitle: 'Drinking a glass of water before meals helps digestion.',
        colorHex: '#3B82F6',
        createdAt: serverTimestamp(),
      })

      // Simple feedback so you know it ran.
      // eslint-disable-next-line no-alert
      alert('Test data injected. The dashboard will update shortly.')
    } catch (err) {
      console.error('Failed to inject test data', err)
      // eslint-disable-next-line no-alert
      alert('Failed to inject test data. Check the console for details.')
    }
  }

  return (
    <div className="admin-root d-flex min-vh-100">
      {/* Sidebar */}
      <aside className="admin-sidebar d-flex flex-column p-3 gap-3">
        <div className="d-flex align-items-center gap-2 admin-logo mb-2">
          <span className="admin-logo-dot" />
          <span className="fw-semibold">TestApp3 Admin</span>
        </div>
        <div className="text-muted small mb-2">Control center</div>

        <nav className="nav nav-pills flex-column gap-2">
          <button
            type="button"
            className={`nav-link admin-nav-link ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => setActiveTab('overview')}
          >
            Overview
          </button>
          <button
            type="button"
            className={`nav-link admin-nav-link ${activeTab === 'users' ? 'active' : ''}`}
            onClick={() => setActiveTab('users')}
          >
            Users
          </button>
          <button
            type="button"
            className={`nav-link admin-nav-link ${activeTab === 'mealTips' ? 'active' : ''}`}
            onClick={() => setActiveTab('mealTips')}
          >
            Meal tips
          </button>
        </nav>

        <div className="mt-auto pt-3 admin-sidebar-footer small text-muted">
          <div>Status: {tipsLoading || usersLoading ? 'Syncing…' : 'Live'}</div>
          <div>Meal tips: {tips.length}</div>
          <div>Users: {users.length}</div>
        </div>
      </aside>

      {/* Main content */}
      <main className="admin-main flex-fill">
        <header className="admin-topbar d-flex justify-content-between align-items-center">
          <div className="d-flex flex-column">
            <div className="admin-topbar-title">Dashboard</div>
            <small className="text-muted">
              {activeTab === 'overview' && 'High-level stats for your app'}
              {activeTab === 'users' && 'See all users that have a saved profile'}
              {activeTab === 'mealTips' && 'Create and manage healthy meal tips'}
            </small>
          </div>
          <div className="d-flex align-items-center gap-2">
            <button
              type="button"
              className="btn btn-sm btn-outline-secondary ms-2"
              onClick={injectTestData}
            >
              Inject test data
            </button>
          </div>
        </header>

        <div className="container-fluid px-0">
          {/* Overview */}
          {activeTab === 'overview' && (
            <div className="row g-3 mb-4">
              <div className="col-md-4">
                <div className="admin-stat-card h-100 d-flex flex-column gap-2">
                  <div className="d-flex justify-content-between align-items-center">
                    <span className="admin-stat-label">Total users</span>
                    <span className="admin-stat-chip">Profiles</span>
                  </div>
                  <div className="admin-stat-value">{usersLoading ? '…' : users.length}</div>
                  {usersError && (
                    <div className="text-danger small mt-1">{usersError}</div>
                  )}
                </div>
              </div>
              <div className="col-md-4">
                <div className="admin-stat-card h-100 d-flex flex-column gap-2">
                  <div className="d-flex justify-content-between align-items-center">
                    <span className="admin-stat-label">Meal tips</span>
                    <span className="admin-stat-chip">Content</span>
                  </div>
                  <div className="admin-stat-value">{tipsLoading ? '…' : tips.length}</div>
                  {tipsError && (
                    <div className="text-danger small mt-1">{tipsError}</div>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* Users */}
          {activeTab === 'users' && (
            <div className="admin-section-card mb-4">
              <div className="d-flex justify-content-between align-items-center mb-3">
                <h2 className="admin-section-title mb-0">Users</h2>
                <span className="badge badge-soft">
                  {usersLoading ? 'Loading…' : `${users.length} user${users.length === 1 ? '' : 's'}`}
                </span>
              </div>
              {usersLoading && <p className="text-muted mb-0">Loading users…</p>}
              {usersError && !usersLoading && (
                <p className="text-danger mb-3">{usersError}</p>
              )}
              {!usersLoading && users.length === 0 && !usersError && (
                <p className="text-muted mb-0">No users found yet.</p>
              )}
              {!usersLoading && users.length > 0 && (
                <div className="table-responsive mt-2">
                  <table className="table table-sm align-middle table-dark-soft table-striped mb-0">
                    <thead>
                      <tr>
                        <th>UID</th>
                        <th>Name</th>
                        <th>Height (cm)</th>
                        <th>Weight (kg)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {users.map((user) => (
                        <tr key={user.id}>
                          <td className="text-truncate" style={{ maxWidth: 160 }}>
                            {user.id}
                          </td>
                          <td>{user.nickname || 'Unknown'}</td>
                          <td>{user.heightCm || '—'}</td>
                          <td>{user.weightKg || '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* Meal tips manager */}
          {activeTab === 'mealTips' && (
            <div className="row g-3 mb-4">
              <div className="col-lg-5">
                <div className="admin-section-card mb-3">
                  <h2 className="admin-section-title mb-3">
                    {form.id == null ? 'Create tip' : 'Edit tip'}
                  </h2>

                  {tipsError && !tipsLoading && (
                    <p className="text-danger small mb-3">{tipsError}</p>
                  )}

                  <form onSubmit={handleSubmit}>
                    <div className="mb-3">
                      <label className="form-label">Title</label>
                      <input
                        name="title"
                        value={form.title}
                        onChange={handleChange}
                        className="form-control"
                        placeholder="Tip title"
                      />
                    </div>
                    <div className="mb-3">
                      <label className="form-label">Description</label>
                      <textarea
                        name="subtitle"
                        value={form.subtitle}
                        onChange={handleChange}
                        className="form-control"
                        rows={3}
                        placeholder="Tip description"
                      />
                    </div>
                    <div className="mb-3">
                      <label className="form-label">Color</label>
                      <div className="d-flex align-items-center gap-2">
                        <input
                          type="color"
                          name="colorHex"
                          value={form.colorHex}
                          onChange={handleChange}
                          className="form-control form-control-color"
                          title="Pick a color"
                        />
                        <input
                          name="colorHex"
                          value={form.colorHex}
                          onChange={handleChange}
                          className="form-control"
                          style={{ maxWidth: 140 }}
                          placeholder="#FF8A65"
                        />
                      </div>
                    </div>
                    <div className="d-flex gap-2">
                      <button type="submit" className="btn btn-primary">
                        {form.id == null ? 'Add tip' : 'Save changes'}
                      </button>
                      {form.id != null && (
                        <button
                          type="button"
                          onClick={resetForm}
                          className="btn btn-outline-secondary"
                        >
                          Cancel
                        </button>
                      )}
                    </div>
                  </form>
                </div>
              </div>

              <div className="col-lg-7">
                <div className="admin-section-card h-100">
                  <div className="d-flex justify-content-between align-items-center mb-3">
                    <h2 className="admin-section-title mb-0">Existing tips</h2>
                    <span className="badge badge-soft">
                      {tipsLoading ? 'Loading…' : `${tips.length} item${tips.length === 1 ? '' : 's'}`}
                    </span>
                  </div>

                  {tipsLoading && <p className="text-muted mb-0">Loading meal tips…</p>}

                  {!tipsLoading && (
                    <div className="table-responsive">
                      <table className="table table-sm align-middle table-dark-soft table-striped mb-0">
                        <thead>
                          <tr>
                            <th>Title</th>
                            <th>Subtitle</th>
                            <th>Color</th>
                            <th style={{ width: 140 }}>Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {tips.map((tip) => (
                            <tr key={tip.id}>
                              <td>{tip.title}</td>
                              <td className="text-truncate" style={{ maxWidth: 260 }}>
                                {tip.subtitle}
                              </td>
                              <td>
                                <span
                                  className="badge rounded-pill"
                                  style={{
                                    backgroundColor: '#0f172a',
                                    border: `1px solid ${tip.colorHex || '#64748b'}`,
                                    color: tip.colorHex || '#e5e7eb',
                                  }}
                                >
                                  {tip.colorHex}
                                </span>
                              </td>
                              <td>
                                <button
                                  type="button"
                                  onClick={() => handleEdit(tip)}
                                  className="btn btn-sm btn-outline-primary me-2"
                                >
                                  Edit
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDelete(tip.id)}
                                  className="btn btn-sm btn-outline-danger"
                                >
                                  Delete
                                </button>
                              </td>
                            </tr>
                          ))}
                          {tips.length === 0 && !tipsLoading && (
                            <tr>
                              <td colSpan={4} className="text-center text-muted">
                                No meal tips yet
                              </td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  )
}

export default App
